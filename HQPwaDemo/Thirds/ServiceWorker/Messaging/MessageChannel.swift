import Foundation
import JavaScriptCore

/// 遵循 JSExport 协议，提供 MessageChannel 方法给 js 调用
@objc public protocol MessageChannelExports: JSExport {
    var port1: SWMessagePort { get }
    var port2: SWMessagePort { get }
    init()
}

/// An implementation of the JavaScript MessageChannel object:
/// https://developer.mozilla.org/en-US/docs/Web/API/MessageChannel
/// This is basically just a pair of MessagePorts, connected to each other.
/// MessageChannel 类定义。用来创建新的消息通道，并通过两个 SWMessagePort 来发送数据
@objc public class MessageChannel: NSObject, MessageChannelExports {
    public let port1: SWMessagePort
    public let port2: SWMessagePort

    override public required init() {
        self.port1 = SWMessagePort()
        self.port2 = SWMessagePort()
        super.init()
        self.port1.targetPort = self.port2
        self.port2.targetPort = self.port1
    }
}
