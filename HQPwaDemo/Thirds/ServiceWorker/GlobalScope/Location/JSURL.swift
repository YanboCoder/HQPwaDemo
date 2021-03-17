import Foundation
import JavaScriptCore

// 遵循 JSExport 协议，提供 JSURL 方法及属性给 js 调用
@objc public protocol JSURLExports: JSExport {
    var href: String { get set }
    var `protocol`: String { get set }
    var host: String { get set }
    var hostname: String { get set }
    var origin: String { get set }
    var port: String { get set }
    var pathname: String { get set }
    var search: String { get set }
    var searchParams: URLSearchParams { get }

    init?(url: JSValue, relativeTo: JSValue)
}

/// An implementation of the JS URL object: https://developer.mozilla.org/en-US/docs/Web/API/URL
/// JS URL 对应的 OC 类实现
@objc public class JSURL: LocationBase, JSURLExports {
    // 初始化方法，返回 JSURL 
    // url: URL 的相对或绝对路径
    // relativeTo: url 为相对路径时的基类 URL，默认为 undefined。若 url 为绝对路径，则忽略其值
    public required init?(url: JSValue, relativeTo: JSValue) {
        do {
            var parsedRelative: URL?

            if relativeTo.isUndefined == false {
                guard let relative = URL(string: relativeTo.toString()), relative.host != nil, relative.scheme != nil else {
                    throw ErrorMessage("Invalid base URL")
                }
                parsedRelative = relative
            }

            guard let parsedURL = URL(string: url.toString(), relativeTo: parsedRelative), parsedURL.host != nil, parsedURL.scheme != nil else {
                throw ErrorMessage("Invalid URL")
            }

            super.init(withURL: parsedURL)

        } catch {
            let err = JSValue(newErrorFromMessage: "\(error)", in: url.context)
            url.context.exception = err
            return nil
        }
    }
}
