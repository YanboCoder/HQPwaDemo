import Foundation
import JavaScriptCore

/// Base class used by both JSURL and WorkerLocation (which have different JSExports, so
/// need to be different classes). Is basically a quick map between a URL object and
/// the JS API: https://developer.mozilla.org/en-US/docs/Web/API/URL
/// JSURL 和 WorkerLocation 的基类，用来实现 URL 对象和 JS API 的快速映射
@objc public class LocationBase: NSObject {
    // 声明 components，类型为 URLComponents，用来解析或构造 URLs
    fileprivate var components: URLComponents
    
    // 声明 searchParams，为自定义 URLSearchParams 类型，用来解析或构造查询参数
    @objc public let searchParams: URLSearchParams

    // 初始化方法，赋值 components、searchParams
    init?(withURL: URL) {
        guard let components = URLComponents(url: withURL, resolvingAgainstBaseURL: true) else {
            return nil
        }
        self.components = components
        self.searchParams = URLSearchParams(components: components)
    }

    // 返回包含整个 URL 的字符串，类型为 String
    @objc public var href: String {
        get {
            self.components.url?.absoluteString ?? ""
        }
        set(value) {
            do {
                guard let newURL = URL(string: value) else {
                    throw ErrorMessage("Could not parse value provided")
                }

                guard let components = URLComponents(url: newURL, resolvingAgainstBaseURL: true) else {
                    throw ErrorMessage("Could not create URL components")
                }

                self.components = components

            } catch {
                let err = JSValue(newErrorFromMessage: "\(error)", in: JSContext.current())
                JSContext.current().exception = err
                return
            }
        }
    }

    // 返回 URL 的协议头，以 ":" 结尾，例如 "https:"
    @objc public var `protocol`: String {
        get {
            if let scheme = components.scheme {
                return scheme + ":"
            } else {
                return ""
            }
        }
        set(value) {
            self.components.scheme = value
        }
    }

    // 返回主机名，字符串类型。如果端口不为空，则拼接 ":" + 端口号返回
    @objc public var host: String {
        get {
            var host = self.hostname

            if let port = self.components.port {
                host += ":" + String(port)
            }

            return host
        }
        set(value) {
            guard let newComponents = URLComponents(string: value) else {
                return
            }

            self.hostname = newComponents.host ?? ""

            if let port = newComponents.port {
                self.port = String(port)
            }
        }
    }

    // 返回 URL 域名
    @objc public var hostname: String {
        get {
            return self.components.host ?? ""
        }
        set(value) {
            self.components.host = value
        }
    }

    // 返回其协议 + "//" + 主机名
    // 对于 http、https: URLs，一般为 "https://apple.com"
    // 对于 File:, 其值依据浏览器来确定
    // 对于 Blob:, 其值一般为 Blob: 之后的 URL 的 origin，例如 "blob:https://mozilla.org" 返回 "https://mozilla.org"
    @objc public var origin: String {
        get {
            return "\(self.protocol)//\(self.host)"
        }
        set(value) {
            // As observed in Chrome, this doesn't seem to do anything
        }
    }

    // 返回端口号，如果不存在，则返回空
    @objc public var port: String {
        get {
            if let portExists = self.components.port {
                return String(portExists)
            } else {
                return ""
            }
        }

        set(value) {
            if let portInt = Int(value) {
                self.components.port = portInt
            }
        }
    }

    // 返回一个字符串，包含一个初始的 '/'，后跟 URL 的路径，不包括查询字符串或片段(如果没有路径，则为空字符串)
    @objc public var pathname: String {
        get {
            return self.components.path
        }
        set(value) {
            self.components.path = value
        }
    }

    // 此属性是一个搜索字符串，也称为查询字符串，即包含'?'，后跟 URL 的参数
    @objc public var search: String {
        get {
            self.components.query.map { "?\($0)" } ?? ""
        }
        set(value) {
            self.components.query = value
        }
    }

    // 一个字符串，其中包含一个'#'，后跟 URL 的片段标识符。
    // 该片段不是 percent-decoded 。如果 URL 没有片段标识符，则该属性包含一个空字符串- ""。
    @objc public var _hash: String {
        get {
            if let fragment = self.components.fragment {
                return "#" + fragment
            } else {
                return ""
            }
        }
        set(value) {
            self.components.fragment = value
        }
    }

    // 获取当前对象
    internal static func getCurrentInstance<T: LocationBase>() -> T? {
        guard let currentContext = JSContext.current() else {
            Log.error?("Somehow called URL hash getter outside of a JSContext. Should never happen")
            return nil
        }

        guard let this = JSContext.currentThis().toObjectOf(T.self) as? T else {
            currentContext.exception = currentContext
                .objectForKeyedSubscript("TypeError")
                .construct(withArguments: ["self type check failed for Objective-C instance method"])

            return nil
        }

        return this
    }

    // _hash getter 方法
    fileprivate static let hashGetter: @convention(block) () -> String? = {
        guard let locationInstance = getCurrentInstance() else {
            return nil
        }

        return locationInstance._hash
    }

    // _hash setter 方法
    fileprivate static let hashSetter: @convention(block) (String) -> Void = { value in
        guard let locationInstance = getCurrentInstance() else {
            return
        }
        locationInstance._hash = value
    }

    // 构造 JSValue 类型值，来处理 hash 命名冲突问题，供 JS 调用
    internal static func createJSValue(for context: JSContext) throws -> JSValue {
        guard let jsVal = JSValue(object: self, in: context) else {
            throw ErrorMessage("Could not create JSValue instance of class")
        }

        /// We can't use 'hash' as a property in native code because it's used by Objective C (grr)
        /// so we have to resort to this total hack to get hash back in JS environments.

        jsVal.objectForKeyedSubscript("prototype").defineProperty("hash", descriptor: [
            "get": unsafeBitCast(self.hashGetter, to: AnyObject.self),
            "set": unsafeBitCast(self.hashSetter, to: AnyObject.self)
        ])

        return jsVal
    }
}
