# YTSocket

YTSocket helps you to connect TCP Sockets. You can write your own handler based on your socket implementation using YTSocketHandler protocol. It has two different types of handlers built in :

#### YTSocketHandlerWithSizeHeader

Packets are sent and received with 4 bytes size header.

#### YTSocketHandlerWithDemiliter

Packets are splitted with a demilimiter. Default is null char : "\0"

## Handling Response

YTSocket expects a response from the server for each sent packet and the response is exposed with a YTResponse.

```
sock?.send(message: "Hello World 👍", onResponse: { (r: YTResponse) in
                self.addLog(r.content!);
});
```

Ah yes, no problems with emojis.

## Usage

```
let handler = YTSocketHandlerWithDemiliter(delimiter: "\0");
sock = YTSocket(endPoint: "127.0.0.1", port: 8888, handler: handler);

//Configure
sock?.slowConnectionAlertInSeconds = 10;
sock?.timeoutThresholdInSeconds = 20;
sock?.logging = true;

sock?.delegate = self;
sock?.connect();
```

```
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
```

## Server

Checkout [this](https://github.com/yasinturkdogan/JavaSocketSample) Java Sample for an endpoint
