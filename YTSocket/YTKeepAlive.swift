//
//  YTKeepAlive.swift
//  YTSocket
//
//  Created by Yasin Turkdogan on 1/5/17.
//  Copyright © 2017 yasinturkdogan. All rights reserved.
//

import Foundation

public class YTKeepAlive {

    fileprivate let intervalInSeconds: Int!;
    fileprivate let socket: YTSocket!
    fileprivate var aliveTimer: Timer?

    init(socket: YTSocket, intervalInSeconds: Int) {
        self.socket = socket;
        self.intervalInSeconds = intervalInSeconds;
    }

    public func start() {
        aliveTimer = Timer.scheduledTimer(timeInterval: TimeInterval(intervalInSeconds), target: self, selector: #selector(sendAlive), userInfo: nil, repeats: true);
        aliveTimer!.tolerance = 5;
    }

    public func stop() {
        aliveTimer?.invalidate();
        aliveTimer = nil;
    }

    @objc internal func sendAlive() {
        if (socket.state.isConnected()) {
            socket.send(message: "\0");
        }
    }
}
