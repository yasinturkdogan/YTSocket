//
//  YTSocket.swift
//  YTSocket
//
//  Created by Yasin Turkdogan on 1/4/17.
//  Copyright © 2017 yasinturkdogan. All rights reserved.
//

import Foundation

public protocol YTSocketDelegate {

    func onConnectionInProgress(_ socket: YTSocket);

    func onConnect(_ socket: YTSocket);

    func onDisconnect(_ socket: YTSocket);

    func onSlowConnection(_ socket: YTSocket);

    func onConnectionError(_ socket: YTSocket);
}

public protocol YTSocketHandler {
    func hasBytesAvailable(inputStream: InputStream) -> String?;

    func write(outputStream: OutputStream, value: String) -> Bool;
}

public enum YTSocketState {

    case Connected;
    case ConnectionInProgress;
    case Transmitting;
    case Disconnected;

    func isConnected() -> Bool {
        return self == .Connected || self == .Transmitting;
    }

    func isDisconnected() -> Bool {
        return self == .Disconnected || self == .ConnectionInProgress;
    }

    func isAvailable() -> Bool {
        return self == .Connected;
    }
}

public class YTSocket: NSObject {

    public var state: YTSocketState = .Disconnected;
    public var timeoutThresholdInSeconds: Int = 20;
    public var slowConnectionAlertInSeconds: Int = 10;
    public var logging: Bool = true;
    public var retryCount: Int = 10;
    public var delegate: YTSocketDelegate?

    private var failCount: Int = 0;
    private var packetQueue: Array<YTPacket> = [];
    private var timeoutTimer: Timer?
    private var endPoint: String!;
    private var port: Int!;

    fileprivate var inputStream: InputStream!
    fileprivate var outputStream: OutputStream!
    fileprivate var handler: YTSocketHandler!

    init(endPoint: String, port: Int, handler: YTSocketHandler) {
        super.init();

        self.endPoint = endPoint;
        self.port = port;
        self.handler = handler;
    }

    public func checkTimeout() {
        if let packetInProgress = packetQueue.first {
            if (packetInProgress.duration() > timeoutThresholdInSeconds) {
                self.onDisconnect();
            } else if (packetInProgress.duration() > slowConnectionAlertInSeconds) {
                delegate?.onSlowConnection(self);
            }
        }
    }

    public func connect() {
        if (self.state.isConnected() || self.state == .ConnectionInProgress) {
            log("Already connected or connection in progress")
            return;
        }

        log("Connecting to " + endPoint + ":" + port.description);
        self.state = .ConnectionInProgress;
        delegate?.onConnectionInProgress(self);

        var readStream: Unmanaged<CFReadStream>?;
        var writeStream: Unmanaged<CFWriteStream>?;

        CFStreamCreatePairWithSocketToHost(nil, endPoint as CFString!, UInt32(port), &readStream, &writeStream);

        self.inputStream = readStream!.takeRetainedValue();
        self.outputStream = writeStream!.takeRetainedValue();

        self.inputStream.delegate = self;
        self.outputStream.delegate = self;

        self.inputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode);
        self.outputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode);

        self.inputStream.open();
        self.outputStream.open();
    }

    public func disconnect() {

        if (self.state == .Disconnected) {
            log("Not connected");
            return;
        }

        while packetQueue.count > 0 {
            packetQueue.removeFirst().timeout();
        }

        //Disable reconnect attempts
        failCount = Int.max;
        closeConnection();
    }

    public func send(message: String, onResponse: YTResponseClosure? = nil) {
        if (message.isEmpty) {
            log("Can not send empty packet");
            return;
        }

        let packet = YTPacket(content: message, onResponse: onResponse);

        if (state.isConnected() == false) {
            log("Not connected");
            packet.complete(with: YTResponse(content: nil, type: .NotConnected));
            return;
        }
        packetQueue.append(packet);
        processQueue();

    }

    fileprivate func onConnect() {
        log("Connected!");

        state = .Connected;
        failCount = 0;

        timeoutTimer?.invalidate();
        timeoutTimer = nil;
        timeoutTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkTimeout), userInfo: nil, repeats: true);
        timeoutTimer!.tolerance = 1;

        delegate?.onConnect(self);
    }

    fileprivate func onDisconnect() {

        failCount = failCount + 1;

        while packetQueue.count > 0 {
            packetQueue.removeFirst().timeout();
        }

        closeConnection();

        if (failCount < retryCount) {
            reconnect();
        } else {
            log("Connection error!")
            delegate?.onConnectionError(self);
        }
    }

    fileprivate func onResponseReceived(response: YTResponse) {
        if let packet = packetQueue.first {
            packet.complete(with: response);
            packetQueue.removeFirst();
        }

        if (state == .Transmitting) {
            state = .Connected;
        }
        processQueue();
    }

    fileprivate func processQueue() {
        if (!self.state.isAvailable()) {
            return;
        }

        if let packet = packetQueue.first {
            self.state = .Transmitting;
            packet.start();
            send(value: packet.content);
        }
    }

    private func send(value: String) {
        log("Sending :" + value);
        let success = handler.write(outputStream: outputStream, value: value);
        if (success == false) {
            log("An error occurred while preparing message");
        } else {
            log("Message sent");
        }
    }

    private func reconnect() {

        delegate?.onConnectionInProgress(self);

        log("Trying to reconnect. Attempt #" + failCount.description);
        YTRun.afterDelay(Double(failCount),
                block: { () -> Void in
                    self.connect();
                }
        );
    }

    private func closeConnection() {
        log("Socket disconnected");

        self.state = .Disconnected;

        packetQueue.removeAll();

        timeoutTimer?.invalidate();
        timeoutTimer = nil;

        if (inputStream != nil) {
            self.inputStream.close();
            self.inputStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            self.inputStream.delegate = nil;
            self.inputStream = nil;
        }

        if (outputStream != nil) {
            self.outputStream.close();
            self.outputStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            self.outputStream.delegate = nil;
            self.outputStream = nil;
        }
        delegate?.onDisconnect(self);
    }

    fileprivate func log(_ message: String) {
        if (logging) {
            print(message);
        }

    }
}

extension YTSocket: StreamDelegate {

    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {

        if (aStream == inputStream) {
            if (eventCode == .openCompleted) {
                log("Input OpenCompleted");
            } else if (eventCode == .hasBytesAvailable) {
                log("Input HasBytesAvaible");

                while (inputStream != nil && inputStream.hasBytesAvailable) {
                    if let message = handler.hasBytesAvailable(inputStream: inputStream) {
                        log("Response received: \(message)");
                        onResponseReceived(response: YTResponse(content: message, type: .Success));
                    }
                }
            } else if (eventCode == .hasSpaceAvailable) {
                log("Input HasSpaceAvailable");
            } else if (eventCode == .errorOccurred) {
                log("Input ErrorOccurred");
                self.onDisconnect();

            } else if (eventCode == .endEncountered) {
                log("Input End Encountered");
                self.onDisconnect();
            } else {
                log("Unknown Input Stream Event : " + eventCode.rawValue.description);
            }
        } else {
            if (eventCode == .openCompleted) {
                log("Output Open Completed");
            } else if (eventCode == .hasBytesAvailable) {
                log("Output HasBytesAvaible");
            } else if (eventCode == .hasSpaceAvailable) {
                log("Output HasSpaceAvailable");
                if (state.isDisconnected()) {
                    self.onConnect();
                }
            } else if (eventCode == .errorOccurred) {
                log("Output ErrorOccurred");
                self.onDisconnect();
            } else if (eventCode == .endEncountered) {
                log("Output End Encountered");
                self.onDisconnect();
            } else {
                log("Unknown Output Stream Event : " + eventCode.rawValue.description);
            }
        }
    }
}
