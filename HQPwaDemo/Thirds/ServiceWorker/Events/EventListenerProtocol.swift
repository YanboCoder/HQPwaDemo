import Foundation

/// We have different types of event listener (JSEventLister and SwiftEventListener)
/// so we ensure that both adhere to this same protocol, allowing them to be used
/// interchangably.
/// EventListener 协议声明，用来确保 JSEventLister 和 SwiftEventListener 遵循相同的协议，可以互相调用
protocol EventListener {
    func dispatch(_: Event)
    var eventName: String { get }
}
