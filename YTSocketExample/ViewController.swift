//
//  ViewController.swift
//  YTSocketExample
//
//  Created by Yasin Turkdogan on 1/6/17.
//  Copyright © 2017 yasinturkdogan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textfield: UITextField!
    @IBOutlet weak var output: UITextView!

    var sock: YTSocket?

    override func viewDidLoad() {
        super.viewDidLoad()
        let handler = YTSocketHandlerWithDemiliter(delimiter: "\0");
        sock = YTSocket(endPoint: "127.0.0.1", port: 8888, handler: handler);

        //Configure
        sock?.slowConnectionAlertInSeconds = 10;
        sock?.timeoutThresholdInSeconds = 20;
        sock?.logging = true;

        sock?.delegate = self;
        sock?.connect();
    }

    fileprivate func addLog(_ log: String) {
        output.text = log + "\n" + output.text!
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if (sock!.state.isConnected()) {
            self.addLog("Sending :" + textField.text!);
            sock?.send(message: textField.text!, onResponse: { (r: YTResponse) in
                self.addLog(r.content!);
            })
        }
        textField.text = "";
        return true;
    }
}

extension ViewController: YTSocketDelegate {
    func onConnect(_ socket: YTSocket) {
        addLog("Connected!");
    }

    func onDisconnect(_ socket: YTSocket) {
        addLog("Disconnected");
    }

    func onSlowConnection(_ socket: YTSocket) {
        addLog("Slow Connection Alert!");
    }

    func onConnectionError(_ socket: YTSocket) {
        addLog("Connection Error");
    }

    func onConnectionInProgress(_ socket: YTSocket) {
        addLog("Connection In Progress");
    }
}

