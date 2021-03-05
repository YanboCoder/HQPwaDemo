import Foundation
import JavaScriptCore
import PromiseKit

public extension Promise {
    /// A convenience function added to all promises, to turn them into
    /// JS promises quickly and easily.
    func toJSPromiseInCurrentContext() -> JSValue? {
        guard let ctx = JSContext.current() else {
            fatalError("Cannot call toJSPromiseInCurrentContext() outside of a JSContext")
        }

        do {
            let jsp = try JSContextPromise(newPromiseInContext: ctx)
            self.done { response -> Void in
                jsp.fulfill(response)
            }
            .catch { error in
                jsp.reject(error)
            }
            return jsp.jsValue
        } catch {
            let err = JSValue(newErrorFromMessage: "\(error)", in: ctx)
            ctx.exception = err
            return nil
        }
    }
}
