import Foundation

/// Extension of ClientProtocol that specifically handles webviews
/// ClientProtocol 扩展，用来处理 webviews
@objc public protocol WindowClientProtocol: ClientProtocol {
    func focus(_ cb: (Error?, WindowClientProtocol?) -> Void)
    func navigate(to: URL, _ cb: (Error?, WindowClientProtocol?) -> Void)

    var focused: Bool { get }
    var visibilityState: WindowClientVisibilityState { get }
}
