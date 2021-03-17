import Foundation
import JavaScriptCore
import PromiseKit

/// 遵循 JSExport 协议，提供 FetchEvent 方法给 js 调用
@objc protocol FetchEventExports: Event, JSExport {
    func respondWith(_: JSValue)
    var request: FetchRequest { get }
}

/// Similar to an ExtendableEvent, but a FetchEvent (https://developer.mozilla.org/en-US/docs/Web/API/FetchEvent)
/// exposes respondWith() instead of waitUntil(), because we want to be able to return a FetchResponse after
/// resolving promises.
/// FetchEvent 类定义了 fetch 事件的事件类型
@objc public class FetchEvent: NSObject, FetchEventExports {
    /// All FetchEvents must have a FetchRequest attached for the worker to respond to.
    /// 用来标记触发 worker 响应的请求
    let request: FetchRequest

    // 声明 respondValue
    fileprivate var respondValue: JSValue?
    
    // 标记事件类型，固定为 fetch
    public let type = "fetch"

    // 用来阻止浏览器的默认 fetch 行为，允许自己构建 response
    func respondWith(_ val: JSValue) {
        if self.respondValue != nil {
            // Unlike waitUntil(), you can only call respondWith() once. So we throw an error if the client
            // code tries twice.

            let err = JSValue(newErrorFromMessage: "respondWith() has already been called", in: val.context)
            val.context.exception = err
            return
        }

        guard let resolved = val.context
            // It is possible to call e.respondWith(new Response("blah")) rather than return a promise. So we
            // quickly call Promise.resolve() to ensure whatever we've been provided is a promise.
            .evaluateScript("(val) => Promise.resolve(val)")
            .call(withArguments: [val]) else {
            // There shouldn't (AFAIK?) be any reason for Promise.resolve() to fail, but you never know.

            let err = JSValue(newErrorFromMessage: "Could not call Promise.resolve() on provided value", in: val.context)
            val.context.exception = err
            return
        }

        self.respondValue = resolved
    }

    // 初始化方法， request 赋值
    public init(request: FetchRequest) {
        self.request = request
        super.init()
    }

    // 执行 resolve 方法
    public func resolve(in _: ServiceWorker) throws -> Promise<FetchResponseProtocol?> {
        guard let promise = self.respondValue else {
            // if e.respondWith() was never called that's perfectly valid - we resolve the
            // promise with no FetchResponse having been provided.

            return Promise.value(nil)
        }

        guard let exec = ServiceWorkerExecutionEnvironment.contexts.object(forKey: promise.context) else {
            // It's possible that someone might try using this in a JSContext that is not a ServiceWorker.
            // So we need to double-check that we do actually have a ServiceWorkerExecutionEnvironment, and
            // thus a specific thread, to resolve this promise to.

            return Promise(error: ErrorMessage("Could not get execution environment for this JSContext"))
        }

        // The JSContextPromise resolve() handles the cast from JSValue -> FetchResponseProtocol. It'll
        // throw if provided anything that isn't compatible.

        return JSContextPromise(jsValue: promise, thread: exec.thread).resolve()
    }
}
