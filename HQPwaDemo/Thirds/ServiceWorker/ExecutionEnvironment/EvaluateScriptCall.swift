import Foundation
import JavaScriptCore
import PromiseKit

// 扩展 ServiceWorkerExecutionEnvironment 类方法
extension ServiceWorkerExecutionEnvironment {
    // 自定义 Promise 回调
    class PromiseWrappedCall: NSObject {
        internal let seal: Resolver<Any?>
        internal let promise: Promise<Any?>

        override init() {
            (self.promise, self.seal) = Promise<Any?>.pending()
        }

        func resolve() -> Promise<Any?> {
            return self.promise
        }

        func resolveVoid() -> Promise<Void> {
            return self.promise.done { _ in () }
        }
    }

    // JS 回调类型枚举值定义
    @objc enum EvaluateReturnType: Int {
        case void
        case object
        case promise
    }

    // JS 类型回调定义
    @objc internal class EvaluateScriptCall: NSObject {
        let script: String
        let url: URL?
        let returnType: EvaluateReturnType
        let fulfill: (Any?) -> Void
        let reject: (Error) -> Void

        init(script: String, url: URL?, passthrough: PromisePassthrough, returnType: EvaluateReturnType = .object) {
            self.script = script
            self.url = url
            self.returnType = returnType
            self.fulfill = passthrough.fulfill
            self.reject = passthrough.reject
            super.init()
        }
    }

    // JS 方法类型
    typealias FuncType = (JSContext) throws -> Void

    // JSContext 中使用的回调定义
    @objc internal class WithJSContextCall: PromiseWrappedCall {
        let funcToRun: FuncType
        init(_ funcToRun: @escaping FuncType) {
            self.funcToRun = funcToRun
        }
    }

    // 分发事件的回调定义
    @objc internal class DispatchEventCall: PromiseWrappedCall {
        let event: Event
        init(_ event: Event) {
            self.event = event
        }
    }
}
