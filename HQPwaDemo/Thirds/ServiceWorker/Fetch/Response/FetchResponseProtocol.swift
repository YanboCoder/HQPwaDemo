import Foundation
import JavaScriptCore
import PromiseKit

/// These are the FetchProtocol components that we expose to our JS environment
/// 遵循 JSExport 协议，提供 FetchResponseProtocol 方法及属性给 js 调用
@objc public protocol FetchResponseJSExports: JSExport {
    var headers: FetchHeaders { get }
    var statusText: String { get }
    var ok: Bool { get }
    var redirected: Bool { get }
    var bodyUsed: Bool { get }
    var status: Int { get }

    @objc(type)
    var responseTypeString: String { get }

    @objc(url)
    var urlString: String { get }

    //    func getReader() throws -> ReadableStream
    func json() -> JSValue?
    func text() -> JSValue?
    func arrayBuffer() -> JSValue?

    @objc(clone)
    func cloneResponseExports() -> FetchResponseJSExports?

    init?(body: JSValue, options: [String: Any]?)
}

/// Then, in addition to the above, these are the elements we make available natively.
/// I think FetchResponseProxy is now the only class that implements these, so in theory
/// we could flatten this out.
/// FetchResponseProtocol 协议声明，具体实现在 FetchResponseProxy 类中
public protocol FetchResponseProtocol: FetchResponseJSExports {
    func clone() throws -> FetchResponseProtocol
    var internalResponse: FetchResponse { get }
    var responseType: ResponseType { get }
    func text() -> Promise<String>
    func data() -> Promise<Data>
    func json() -> Promise<Any?>
    var streamPipe: StreamPipe? { get }
    var url: URL? { get }
}

/// Just to add a little complication to the mix, this is a special case for caching. Obj-C
/// can't represent the Promises in FetchResponseProtocol, so we have a special-case, Obj-C
/// compatible protocol that lets us get to the inner fetch response.
/// 这是缓存的一种特殊情况，稍微增加一点复杂性。
/// Obj-C 不能表示 FetchResponseProtocol 中的 Promises，所以我们有一个特殊情况下的 Obj-C 兼容协议，它让我们获得内部的 fetch 响应。
@objc public protocol CacheableFetchResponse: FetchResponseJSExports {
    var internalResponse: FetchResponse { get }
}
