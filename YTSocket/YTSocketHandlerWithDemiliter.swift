//
//  YTSocketHandler.swift
//  YTSocket
//
//  Created by Yasin Turkdogan on 1/5/17.
//  Copyright © 2017 yasinturkdogan. All rights reserved.
//

import Foundation

public class YTSocketHandlerWithDemiliter: YTSocketHandler {

    fileprivate var buffer = [UInt8](repeating: 0, count: 2048);
    fileprivate var readBuffer = [UInt8]();
    fileprivate let ending: Data!;

    init(delimiter: String) {
        self.ending = delimiter.data(using: String.Encoding.utf8)!;
    }

    public func hasBytesAvailable(inputStream: InputStream) -> String? {
        let len = inputStream.read(&buffer, maxLength: buffer.count);
        var msg: String? = nil;
        for index in 0 ..< len {
            if (buffer[index] == 0 && readBuffer.count > 0) {
                if let message = String(bytes: readBuffer, encoding: String.Encoding.utf8) {
                    msg = message;
                }

                readBuffer = [];
            } else if (buffer[index] > 0) {
                readBuffer.append(buffer[index]);
            }
        }
        return msg;
    }

    public func write(outputStream: OutputStream, value: String) -> Bool {

        if let data: Data = value.data(using: String.Encoding.utf8) {
            _ = data.withUnsafeBytes {
                outputStream.write($0, maxLength: data.count);
            }
            _ = ending.withUnsafeBytes {
                outputStream.write($0, maxLength: ending.count);
            }
            return true;
        }

        return false;

    }
}
