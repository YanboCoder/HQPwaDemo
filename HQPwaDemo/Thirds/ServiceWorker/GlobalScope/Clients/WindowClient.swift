import Foundation
import JavaScriptCore
import PromiseKit

// 遵循 JSExport 协议，用来提供 WindowClient 方法及属性给 js 调用
@objc protocol WindowClientExports: JSExport {
    func focus() -> JSValue?
    func navigate(_ url: String) -> JSValue?
    var focused: Bool { get }
    var visibilityState: String { get }
}

/// A more specific version of Client, WindowClient: https://developer.mozilla.org/en-US/docs/Web/API/WindowClient
/// also provides information on visibility and focus state (that don't apply to workers etc)
/// WindowClient API 实现（ Client 的子类），提供是否可见和点击状态等信息
@objc class WindowClient: Client, WindowClientExports {
    // 声明 wrapAroundWindow，类型为 WindowClientProtocol
    let wrapAroundWindow: WindowClientProtocol

    // 初始化方法，wrapAroundWindow 赋值
    init(wrapping: WindowClientProtocol) {
        self.wrapAroundWindow = wrapping
        super.init(client: wrapping)
    }

    // MARK: - WindowClientProtocol 方法及属性实现 -
    // 将用户输入的焦点提供给 client，并包装为 Promise 对象返回
    func focus() -> JSValue? {
        return Promise<Client> { seal in

            wrapAroundWindow.focus { err, windowClient in
                if let error = err {
                    seal.reject(error)
                } else if let client = windowClient {
                    seal.fulfill(Client.getOrCreate(from: client))
                }
            }
        }
        .toJSPromiseInCurrentContext()
    }

    // 加载到对应 url 的界面，获取 windowClient，并包装为 Promise 对象返回
    func navigate(_ url: String) -> JSValue? {
        return Promise<WindowClientProtocol> { seal in
            guard let parsedURL = URL(string: url, relativeTo: nil) else {
                return seal.reject(ErrorMessage("Could not parse URL returned by native implementation"))
            }

            self.wrapAroundWindow.navigate(to: parsedURL) { err, windowClient in
                if let error = err {
                    seal.reject(error)
                } else if let window = windowClient {
                    seal.fulfill(window)
                }
            }
        }.toJSPromiseInCurrentContext()
    }

    // 标识当前 WindowClient 是否获取焦点
    var focused: Bool {
        return self.wrapAroundWindow.focused
    }

    // 标识当前 WindowClient 是否可见
    var visibilityState: String {
        return self.wrapAroundWindow.visibilityState.stringValue
    }
}
