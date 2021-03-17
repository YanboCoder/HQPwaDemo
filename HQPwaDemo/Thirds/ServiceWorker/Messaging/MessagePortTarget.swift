import Foundation

/// Normally a MessagePort communicates with another MessagePort (as facilitated
/// by Message Channel) but at times we need to do something different, like set up
/// a proxy to send messages into a SWWebView. This protocol allows us to do that.
/// MessagePortTarget 协议定义。用来从端口传递消息到 SWWebView
public protocol MessagePortTarget: class {
    var started: Bool { get }
    func start()
    func receiveMessage(_: ExtendableMessageEvent)
    func close()
}
