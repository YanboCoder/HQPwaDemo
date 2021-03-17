import Foundation

/// Outlined here: https://developer.mozilla.org/en-US/docs/Web/API/Clients/matchAll
/// Client.matchAll 方法的可选参 -- ClientMatchAllOptions 类定义
@objc public class ClientMatchAllOptions: NSObject {
    // 布尔值。如果为 true，则返回与当前 service worker 共享同一源（origin）的 service worker client；否则，返回由当前 service worker 控制的 client；默认为 false。
    let includeUncontrolled: Bool
    
    // 用来设置想要匹配的 client 类型，可用类型有："window", "worker", "sharedworker", and "all"。默认为 "window"
    let type: String

    // 初始化方法，设置 includeUncontrolled、type
    init(includeUncontrolled: Bool, type: String) {
        self.includeUncontrolled = includeUncontrolled
        self.type = type
    }
}
