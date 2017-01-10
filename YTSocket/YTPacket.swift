//
//  YTCommand.swift
//  YTSocket
//
//  Created by Yasin Turkdogan on 1/5/17.
//  Copyright © 2017 yasinturkdogan. All rights reserved.
//

import Foundation

public class YTPacket {
    public let content: String!;
    public let onResponse: YTResponseClosure?;
    public var startTime: TimeInterval?;

    init(content: String, onResponse: YTResponseClosure?) {
        self.content = content;
        self.onResponse = onResponse;
    }

    public func start() {
        startTime = Date().timeIntervalSince1970;
    }

    public func duration() -> Int {
        if (startTime == nil) {
            return 0;
        }

        return Int(Date().timeIntervalSince1970 - startTime!);
    }

    public func timeout() {
        complete(with: YTResponse(content: nil, type: .Timeout));
    }

    public func complete(with: YTResponse) {
        onResponse?(with);
    }
}
