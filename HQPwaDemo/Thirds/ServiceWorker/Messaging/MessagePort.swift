import Foundation
import JavaScriptCore

/// 遵循 JSExport 协议，提供 MessagePort 方法给 js 调用
@objc public protocol MessagePortExports: JSExport {
    func postMessage(_ message: Any, _ transferList: [Transferable])
    func start()
    var onmessage: JSValue? { get set }
}

/// An implementation of the JavaScript MessagePort class:
/// https://developer.mozilla.org/en-US/docs/Web/API/MessagePort
/// SWMessagePort 类定义
/// 用来定义 MessageChannel 的两个端口之一，允许消息从一个端口传递到另一个端口
@objc public class SWMessagePort: EventTarget, Transferable, MessagePortExports, MessagePortTarget {
    // 表示目标端口
    public weak var targetPort: MessagePortTarget?
    
    // 标记是否开始传递消息
    public var started: Bool = false

    /// MessagePorts don't start sending messages immediately - that's done by calling start()
    /// or setting the onmessage property. Any messages sent before that are queued here.
    /// 初始化消息队列，来管理消息
    fileprivate var queuedMessages: [ExtendableMessageEvent] = []

    // 管理 SwiftEventListener 类型的事件监听
    fileprivate var onMessageListener: SwiftEventListener<ExtendableMessageEvent>?
    
    // 传递的消息
    fileprivate var onmessageValue: JSValue?

    // 初始化方法
    override public init() {
        super.init()
        self.onMessageListener = self.addEventListener("message") { [unowned self] (event: ExtendableMessageEvent) in
            // in JS we can set onmessage directly rather than use addEventListener.
            // so we should mirror that here.
            if let onmessage = self.onmessageValue {
                onmessage.call(withArguments: [event])
            }
        }
    }

    // 注销时，关闭目标端口
    deinit {
        if let target = self.targetPort {
            // If this is being removed then there's no point keeping the target open.
            // But more usefully for us, this also allows us to automatically close
            // MessagePorts that live in SWWebViews (and can't be automatically garbage
            // collected)
            target.close()
        }
    }

    // 当端口接收到消息时会调用
    public var onmessage: JSValue? {
        get {
            return self.onmessageValue
        }
        set(value) {
            self.onmessageValue = value
            // start is called implicitly when onmessage is set:
            // https://developer.mozilla.org/en-US/docs/Web/API/MessagePort/start
            self.start()
        }
    }

    // 发送消息
    // 当使用 EventTarget.addEventListener 时显式调用
    // 使用 MessageChannel.onmessage 时隐式调用
    public func start() {
        self.started = true
        self.queuedMessages.forEach { self.dispatchEvent($0) }
        self.queuedMessages.removeAll()
    }

    // 关闭端口连接
    public func close() {
        self.started = false
    }

    /// Implementation of the JS API method: https://developer.mozilla.org/en-US/docs/Web/API/MessagePort/postMessage
    /// 从端口发送消息，可选择是否将对象的所有权发送给其他浏览器上下文
    public func postMessage(_ message: Any, _ transferList: [Transferable] = []) {
        do {
            guard let targetPort = self.targetPort else {
                throw ErrorMessage("MessagePort does not have a target set")
            }

            guard let ports = transferList as? [SWMessagePort] else {
                throw ErrorMessage("All transferables must be MessagePorts for now")
            }

            let messageEvent = ExtendableMessageEvent(data: message, ports: ports)

            targetPort.receiveMessage(messageEvent)

        } catch {
            if let ctx = JSContext.current() {
                let err = JSValue(newErrorFromMessage: "\(error)", in: ctx)
                ctx.exception = err
            } else {
                Log.error?("\(error)")
            }
        }
    }

    /// Not sure this needs to be specifically tied to ExtendableMessageEvent, but it is
    /// for now.
    /// 接收到消息
    public func receiveMessage(_ evt: ExtendableMessageEvent) {
        if self.started == false {
            self.queuedMessages.append(evt)
        } else {
            self.dispatchEvent(evt)
        }
    }
}
