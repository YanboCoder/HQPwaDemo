import Foundation

/// Outlined here: https://developer.mozilla.org/en-US/docs/Web/API/Clients/matchAll, though
/// not sure we'll ever implement Worker or SharedWorker (not sure how we'd know about them)
/// Client 枚举类型声明
@objc public enum ClientType: Int {
    case Window
    case Worker
    case SharedWorker
}

// Can't use string enums because Objective C doesn't like them
// 应为 Sting 类型，进行转换
extension ClientType {
    var stringValue: String {
        switch self {
        case .SharedWorker:
            return "sharedworker"
        case .Window:
            return "window"
        case .Worker:
            return "worker"
        }
    }
}
