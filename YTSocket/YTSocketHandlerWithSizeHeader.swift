//
//  YTSocketBinary.swift
//  YTSocket
//
//  Created by Yasin Turkdogan on 1/5/17.
//  Copyright © 2017 yasinturkdogan. All rights reserved.
//

import Foundation

public class YTSocketHandlerWithSizeHeader: YTSocketHandler {

    private var requiredSize: Int = 4;
    private var sizeRequired: Bool = true;
    private var readData = NSMutableData();
    private let gzipped: Bool!;

    init(gzipped: Bool) {
        self.gzipped = gzipped;
    }

    public func hasBytesAvailable(inputStream: InputStream) -> String? {
        var newBuffer = [UInt8](repeating: 0, count: requiredSize);
        let len = inputStream.read(&newBuffer, maxLength: requiredSize);

        readData.append(&newBuffer, length: len);

        var msg: String? = nil;
        if (len == requiredSize) {
            if (sizeRequired) {
                var value: UInt32 = 0;
                readData.getBytes(&value, length: 4);
                value = UInt32(bigEndian: value);
                requiredSize = Int(value);
                readData = NSMutableData();
                sizeRequired = false;

            } else {
                if let message = String.init(data: readData as Data, encoding: String.Encoding.utf8) {
                    msg = message;
                }
                requiredSize = 4;
                sizeRequired = true;
                readData = NSMutableData();

            }
        } else {
            requiredSize -= len;
        }
        return msg;
    }

    public func write(outputStream: OutputStream, value: String) -> Bool {
        if var data: Data = value.data(using: String.Encoding.utf8) {
            var cnt: Int32 = Int32(data.count)
            let dataSize = Data(bytes: &cnt, count: 4);
            _ = dataSize.withUnsafeBytes {
                outputStream.write($0, maxLength: 4);
            }
            _ = data.withUnsafeBytes {
                outputStream.write($0, maxLength: data.count);
            }

            return true;
        }

        return false;
    }

}
