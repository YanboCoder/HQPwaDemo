import Foundation
import JavaScriptCore

/// All functions in this protocol should return a Promise resolving to FetchResponse
/// a bool, or string array, depending on function. In retrospect, these should probably
/// be synchronous or use callbacks, and be wrapped internally. Another time.
/// 遵循 JSExport 协议，提供 Cache 方法给 js 调用
/// 此协议中的所有方法都应该返回 Promise
@objc public protocol Cache: JSExport {
    // 接收 request，查找相关 response 后返回。若为空，返回 undefined
    func match(_ request: JSValue, _ options: [String: Any]?) -> JSValue?
    
    // 接收 request 数组，查找相关 response 后返回
    func matchAll(_ request: JSValue, _ options: [String: Any]?) -> JSValue?
    
    // 接收 request，进行查找，将其 response 添加到指定的缓存中
    func add(_ request: JSValue) -> JSValue?
    
    // 接收 request 数组，进行查找，将其 response 添加到指定的缓存中
    func addAll(_ requests: JSValue) -> JSValue?
    
    // 接收 request、response，以键值对的形式添加到缓存
    func put(_ request: FetchRequest, _ response: CacheableFetchResponse) -> JSValue?
    
    // 接收 request，进行查找，删除相应的 response
    func delete(_ request: JSValue, _ options: [String: Any]?) -> JSValue?
    
    // 返回缓存的键名数组
    func keys(_ request: JSValue, _ options: [String: Any]?) -> JSValue?
}
