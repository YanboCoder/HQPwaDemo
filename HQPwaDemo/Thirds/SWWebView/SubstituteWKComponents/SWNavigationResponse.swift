import Foundation
import WebKit

// 跳转响应信息，用于制定响应策略
class SWNavigationResponse: WKNavigationResponse {
    // 标记 webkit 是否可以显示媒体类型
    fileprivate let _canShowMIMEType: Bool
    override var canShowMIMEType: Bool {
        return self._canShowMIMEType
    }

    // 标记是否能跳转到主框架
    fileprivate let _isForMainFrame: Bool
    override var isForMainFrame: Bool {
        return self._isForMainFrame
    }

    // 响应体
    fileprivate let _response: URLResponse
    override var response: URLResponse {
        return self._response
    }

    // 初始化方法
    init(response: URLResponse, isForMainFrame: Bool, canShowMIMEType: Bool) {
        self._response = response
        self._isForMainFrame = isForMainFrame
        self._canShowMIMEType = canShowMIMEType
    }
}
