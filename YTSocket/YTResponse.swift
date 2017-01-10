//
//  YTResult.swift
//  YTSocket
//
//  Created by Yasin Turkdogan on 1/5/17.
//  Copyright © 2017 yasinturkdogan. All rights reserved.
//

import Foundation

public class YTResponse {
    public let content: String?;
    public let type: YTResponseResult!;

    init(content: String?, type: YTResponseResult) {
        self.content = content;
        self.type = type;
    }
}

public enum YTResponseResult {

    case Success;
    case Timeout;
    case Error;
    case NotConnected;
}
