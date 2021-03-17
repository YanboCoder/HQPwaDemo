import Foundation
import JavaScriptCore

/// At their core, events are very simple and only need a type attribute. There
/// are others in JS (like bubbles etc) that we can add later, but for now this
/// is all we need.
/// Event 类声明及实现，目前仅需获取其 type 属性
@objc public protocol Event: JSExport {
    var type: String { get }
}
