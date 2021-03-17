import Foundation
import JavaScriptCore

// 遵循 JSExport 协议，提供 EventTarget 方法 js 调用
@objc protocol EventTargetExports: JSExport {
    func addEventListener(_ name: String, _ funcToRun: JSValue)
    func removeEventListener(_ name: String, _ funcToRun: JSValue)
    func dispatchEvent(_ event: Event)
}

/// Replicating the base EventTarget class used throughout the browser:
/// https://developer.mozilla.org/en-US/docs/Web/API/EventTarget
/// EventTarget 是由对象来实现的接口，使用此接口的对象可以监听并接收事件
@objc public class EventTarget: NSObject, EventTargetExports {
    // 声明 listeners 数组，用来管理 EventListener 对象
    fileprivate var listeners: [EventListener] = []

    // 设置监听
    // 设置一个函数到 worker thread，当指定的事件传递到目标时，该函数将被调用
    func addEventListener(_ name: String, _ funcToRun: JSValue) {
        // We tie our event listeners to the worker thread, so we need to throw
        // an error if trying to use this function off-thread.

        ServiceWorkerExecutionEnvironment.ensureContextIsOnCorrectThread()

        let existing = self.listeners.first(where: { listener in

            // According to a quick test: https://codepen.io/anon/pen/BwVOzr
            // browsers detect when you're adding an event listener for the same
            // function twice, and ensures it is only ever fired once. So we
            // should do the same.

            guard let jsListener = listener as? JSEventListener else {
                // Because we can attach both JS and Swift listeners (still undecided
                // about how wise that is) we first need to check whether the listener
                // is a JSEventListener. If not it's safe to ignore it.

                return false
            }

            return jsListener.eventName == name && jsListener.funcToRun == funcToRun

        })

        if existing != nil {
            return
        }

        self.listeners.append(JSEventListener(name: name, funcToRun: funcToRun, thread: Thread.current))
    }

    // 设置监听
    // 设置一个函数到 worker thread，当指定的事件传递到目标时，该函数将被调用
    func addEventListener<T>(_ name: String, _ callback: @escaping (T) -> Void) -> SwiftEventListener<T> {
        // We can't do the same dupe check we do with JSEventListeners because you can't
        // compare closures like that (if callback == callback is a compile error), so we just
        // ignore that potential issue.
        // 因为 OC 不能像 JS 那样检测闭包是否相同（即 callback == callback 会报错），所以我们忽略这个问题
        
        let listener = SwiftEventListener(name: name, callback)
        self.listeners.append(listener)
        return listener
    }

    // 移除监听
    func removeEventListener<T>(_ listener: SwiftEventListener<T>) {
        guard let idx = self.listeners.firstIndex(where: { existingListener in

            if let swiftListener = existingListener as? SwiftEventListener<T> {
                return swiftListener == listener
            }
            return false

        }) else {
            Log.error?("Tried to remove a listener that isn't attached")
            return
        }
        self.listeners.remove(at: idx)
    }

    // 移除监听
    func removeEventListener(_ name: String, _ funcToRun: JSValue) {
        guard let existing = listeners.firstIndex(where: { listener in

            guard let jsListener = listener as? JSEventListener else {
                return false
            }

            return jsListener.eventName == name && jsListener.funcToRun == funcToRun

        }) else {
            // Browser environments don't throw an error when you try to remove an event
            // listener that doesn't exist, but let's log it as it might be useful in
            // debugging.

            Log.warn?("Tried to remove an event on \(name) but it doesn't exist")
            return
        }

        self.listeners.remove(at: existing)
    }

    // 在指定的 EventTarget 上分发事件
    func dispatchEvent(_ event: Event) {
        self.listeners
            .filter { $0.eventName == event.type }
            .forEach { $0.dispatch(event) }
    }

    // 销毁 EventTarget
    deinit {
        // Make sure that we remove any existing JSValue references when we deinit(). In theory this
        // happens anyway, but JSContext is weird.
        self.clearAllListeners()
    }

    // 移除所有监听
    func clearAllListeners() {
        self.listeners.removeAll()
    }

    /// Add addEventListener, removeEventListener and dispatchEvent to the global object of a JSContext.
    /// 将 EventTarget 方法添加到全局的 JSContext 中
    static func applyJavaScriptListeners(_ from: EventTarget, to context: JSContext) {
        let addConvention: @convention(block) (String, JSValue) -> Void = { name, funcToRun in
            from.addEventListener(name, funcToRun)
        }
        GlobalVariableProvider.add(variable: addConvention, to: context, withName: "addEventListener")

        let removeConvention: @convention(block) (String, JSValue) -> Void = { name, funcToRun in
            from.removeEventListener(name, funcToRun)
        }

        GlobalVariableProvider.add(variable: removeConvention, to: context, withName: "removeEventListener")

        let dispatchConvention: @convention(block) (Event) -> Void = { event in
            from.dispatchEvent(event)
        }

        GlobalVariableProvider.add(variable: dispatchConvention, to: context, withName: "dispatchEvent")
    }
}
