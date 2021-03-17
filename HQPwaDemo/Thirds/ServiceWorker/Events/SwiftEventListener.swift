import Foundation
import JavaScriptCore

/// A native version of JSEventListener, allowing us to attach swift closures to
/// an EventTarget. It's a generic, but inherits from NSObject so that it can be
/// stored in an Obj-C compatible array.
/// SwiftEventListener 类定义，遵循 EventListener 协议
class SwiftEventListener<T>: NSObject, EventListener {
    // 事件名称
    let eventName: String
    
    // 回调方法
    let callback: (T) -> Void

    // 初始化方法，属性赋值
    init(name: String, _ callback: @escaping (T) -> Void) {
        self.eventName = name
        self.callback = callback
        super.init()
    }

    // 分发事件
    func dispatch(_ event: Event) {
        // Because JSEventListeners are not type-specific like Swift ones are, we can't
        // strictly enforce type safety. If the event received is not the expected type
        // (e.g. received a FetchEvent when we were expecting an ExtendableEvent) the
        // event is not dispatched, and a warning is logged.
        
        print("++++++++++++++++\n eventName: \(eventName)\n")
        if let specificEvent = event as? T {
            self.callback(specificEvent)
        } else {
            Log.warn?("Dispatched event \(event), but this listener is for type \(T.self)")
        }
    }
}
