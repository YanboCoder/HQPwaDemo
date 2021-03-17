import Foundation
import JavaScriptCore

/// 遵循 JSExport 协议，提供 MessageEvent 方法给 js 调用
@objc public protocol MessageEventExports: Event, JSExport {
    var data: Any { get }
    var ports: [SWMessagePort] { get }
}

/// ExtendableMessageEvent is like an ExtendableEvent except it also lets you transfer
/// data and an array of transferrables (right now just MessagePort):
/// https://developer.mozilla.org/en-US/docs/Web/API/ExtendableMessageEvent
/// ExtendableMessageEvent 类定义，扩展消息事件生命周期
@objc public class ExtendableMessageEvent: ExtendableEvent, MessageEventExports {
    // 事件传递的信息，可以是任何类型
    public let data: Any
    
    // SWMessagePort 对象数组，SWMessagePort 表示消息通道的端口
    public let ports: [SWMessagePort]

    // 初始化方法，属性赋值，类型定义为 "message"
    public init(data: Any, ports: [SWMessagePort] = []) {
        self.data = data
        self.ports = ports
        super.init(type: "message")
    }
}
