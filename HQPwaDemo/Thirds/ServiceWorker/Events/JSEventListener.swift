import Foundation
import JavaScriptCore

/// A wrapper around a JavaScript function, stored as a JSValue, to be called when
/// an event is dispatched. Also contains a reference to the correct thread to
/// run the function on.
/// JSEventListener 类定义，遵循 EventListener 协议
class JSEventListener: EventListener {
    // 事件名称
    let eventName: String
    
    // 运行的方法
    let funcToRun: JSValue
    
    // 目标线程
    let targetThread: Thread

    // 初始化方法，属性赋值
    init(name: String, funcToRun: JSValue, thread: Thread) {
        self.eventName = name
        self.funcToRun = funcToRun
        self.targetThread = thread
    }

    // 分发事件
    func dispatch(_ event: Event) {
        print("===============\n eventName: \(eventName)\n funcToRun: \(funcToRun)\n targetThread: \(targetThread)\n")
        self.funcToRun.perform(#selector(JSValue.call(withArguments:)), on: self.targetThread, with: [event], waitUntilDone: true)
    }
}
