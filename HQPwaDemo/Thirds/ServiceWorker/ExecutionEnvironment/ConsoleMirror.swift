import Foundation
import JavaScriptCore

// 遵循 JSExport 协议，提供 ConsoleMirror 方法给 js 调用
@objc private protocol ConsoleMirrorExports: JSExport {
    func mirror(_ level: String, _ msg: JSValue)
}

/// JavascriptCore has a fully functional console, just like the browser. But ideally we will also
/// mirror JSC console statements in our logs, too. There are no console events as such, so we have
/// to override the functions on the console object itself.
/// JavascriptCore 有一个功能齐全的控制台，就像浏览器一样。但是我们需要将其输出语句镜像到 OC 的控制台中，所以需要重写其方法来实现此功能
@objc class ConsoleMirror: NSObject, ConsoleMirrorExports {
    // 声明 originalConsole 对象
    var originalConsole: JSValue?

    // 初始化方法
    init(in context: JSContext) throws {
        // 获取控制台输出内容
        self.originalConsole = context.globalObject.objectForKeyedSubscript("console")
        super.init()

        // We do this by replacing the console object with a proxy:
        // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy
        // to the console. This allows us to both intercept calls and send them onwards
        // to the debugging console that might be open.

        guard let proxyFunc = context.evaluateScript("""
             (function(funcToCall) {
                let levels = ["debug", "info", "warn", "error", "log"];
                let originalConsole = console;

                let levelProxy = {
                    apply: function(target, thisArg, argumentsList) {
                        // send to original console logging function
                        target.apply(thisArg, argumentsList);

                        let level = levels.find(l => originalConsole[l] == target);

                        funcToCall(level, argumentsList);
                    }
                };

                let interceptors = levels.map(
                    l => new Proxy(originalConsole[l], levelProxy)
                );

                return new Proxy(originalConsole, {
                    get: function(target, name) {
                        let idx = levels.indexOf(name);
                        if (idx === -1) {
                            // not intercepted
                            return target[name];
                        }
                        return interceptors[idx];
                    }
                });
            })

        """) else {
            throw ErrorMessage("Cannot create console proxy")
        }

        let mirrorConvention: @convention(block) (String, JSValue) -> Void = self.mirror

        guard let consoleProxy = proxyFunc.call(withArguments: [unsafeBitCast(mirrorConvention, to: AnyObject.self)]) else {
            throw ErrorMessage("Could not create instance of console proxy")
        }

        GlobalVariableProvider.add(variable: consoleProxy, to: context, withName: "console")
    }

    /// Not entirely sure if this is necessary, but we remove this object and return the
    /// original console when the worker closes. Hopefully to ensure garbage collection
    /// runs correctly.
    /// 清除对 console 对象的引用，交还给 JS console
    func cleanup() {
        guard let console = self.originalConsole else {
            Log.error?("Cleanup with no original console. This should not happen.")
            return
        }

        console.context.globalObject.setValue(console, forProperty: "console")
        self.originalConsole = nil
    }

    /// The actual function that performs the logging
    /// 实现相关 log 输出的映射
    fileprivate func mirror(_ level: String, _ msg: JSValue) {
        let values = msg.toArray()
            .map { val in

                // This could do with being fleshed out a lot, but basically we
                // leave strings untouched, and replace any objects with string
                // representations of that object.

                if let str = val as? String {
                    return str
                }

                return String(describing: val)
            }
            .joined(separator: ",")

        switch level {
        case "info":
            Log.info?(values)
        case "log":
            Log.info?(values)
        case "debug":
            Log.debug?(values)
        case "warn":
            Log.warn?(values)
        case "error":
            Log.error?(values)
        default:
            // this should never happen (as we specify the levels in the JS above) but just in case...
            Log.error?("Tried to log to JSC console at an unknown level.")
        }
    }
}
