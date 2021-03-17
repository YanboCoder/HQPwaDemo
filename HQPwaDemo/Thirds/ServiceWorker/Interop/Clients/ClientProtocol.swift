import Foundation
import JavaScriptCore

/// The representation of a webview that a service worker sees.
/// ClientProtocol 方法及属性声明，用来表示 service worker 接收到的 webview 对象
@objc public protocol ClientProtocol {
    func postMessage(message: Any?, transferable: [Any]?)
    var id: String { get }
    var type: ClientType { get }
    var url: URL { get }
}
