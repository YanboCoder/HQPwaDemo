import Foundation
import JavaScriptCore

// 遵循 JSExport 协议，提供 WorkerLocation 方法及属性给 js 调用
@objc public protocol WorkerLocationExports: JSExport {
    var href: String { get }
    var `protocol`: String { get }

    var host: String { get }
    var hostname: String { get }
    var origin: String { get }
    var port: String { get }
    var pathname: String { get }
    var search: String { get }
    var searchParams: URLSearchParams { get }
}

/// Basically the same as URL as far as I can, except for the fact that it is
/// read-only. https://developer.mozilla.org/en-US/docs/Web/API/WorkerLocation
/// WorkerLocation 接口定义了 Worker 所执行脚本的绝对位置
/// 这样的对象会初始化每个 worker，并且可以通过 WorkerGlobalScope 获得
/// 通过调用 self.location 获得的 location 属性
/// 该接口仅在 Web worker 上下文中执行的 JavaScript 脚本中可见
@objc(WorkerLocation) public class WorkerLocation: LocationBase, WorkerLocationExports {}
