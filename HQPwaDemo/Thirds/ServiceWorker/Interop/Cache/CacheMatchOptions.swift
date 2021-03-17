import Foundation

/// CacheMatchOptions are outlined here: https://developer.mozilla.org/en-US/docs/Web/API/Cache/match
// 查询参数结构体定义
public struct CacheMatchOptions {
    // 忽略 URL 中的 search 字符串，默认为 false
    let ignoreSearch: Bool
    
    // 忽略请求的 http 方法，通常只允许 GET、HEAD，默认为 false
    let ignoreMethod: Bool
    
    // 忽略 VARY 字段匹配，默认为 false
    let ignoreVary: Bool
    
    // 指定缓存的 cacheName
    let cacheName: String?
}

// 自定义缓存查询参数
public extension CacheMatchOptions {
    /// Just a quick shortcut method to let us construct matching options from a JS object
    static func fromDictionary(opts: [String: Any]) -> CacheMatchOptions {
        let ignoreSearch = opts["ignoreSearch"] as? Bool ?? false
        let ignoreMethod = opts["ignoreMethod"] as? Bool ?? false
        let ignoreVary = opts["ignoreVary"] as? Bool ?? false
        let cacheName: String? = opts["cacheName"] as? String

        return CacheMatchOptions(ignoreSearch: ignoreSearch, ignoreMethod: ignoreMethod, ignoreVary: ignoreVary, cacheName: cacheName)
    }
}
