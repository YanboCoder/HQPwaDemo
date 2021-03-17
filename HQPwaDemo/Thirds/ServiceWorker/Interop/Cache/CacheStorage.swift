import Foundation
import JavaScriptCore

/// Should resolve to JS promises. Like Cache, should probably actually be all native,
/// and be wrapped internally. Otherwise we might end up leaking JSValues everywhere.
/// 遵循 JSExport 协议，提供 CacheStorage 方法给 js 调用
/// 此协议中的所有方法都应该返回 Promise
@objc public protocol CacheStorageJSExports: JSExport {
    // 返回匹配 request 的 cache 对象
    func match(_ request: JSValue, _ options: [String: Any]?) -> JSValue?
    
    // 返回是否存在 cacheName 的 cache 对象，若有，则为 true；否则为 false
    func has(_ cacheName: String) -> JSValue?
    
    // 返回匹配 cacheName 的 cache 对象
    func open(_ cacheName: String) -> JSValue?
    
    // 查询匹配 cacheName 的 cache 对象，存在则删除，返回 true；反之，返回 false
    func delete(_ cacheName: String) -> JSValue?
    
    // 以数组形式返回 caches 的 cacheName
    func keys() -> JSValue?
}

// 遵循 JSExport 协议，提供 CacheStorage 方法给 js 调用
// CacheStorage 用来保存 cache 对象，以键值对形式存储
@objc public protocol CacheStorage: CacheStorageJSExports, JSExport {
    /// This is used to define the Cache object in a worker's global scope - probaby
    /// not strictly necessary, but it matches what browsers do.
    /// 自定义类型，用来区分是哪个浏览器的缓存
    static var CacheClass: Cache.Type { get }
}
