import Foundation
import WebKit

/// We can't manually create WKNavigationActions, so instead we have to do this
// 记录跳转框架信息，用于制定跳转策略
class SWNavigationAction: WKNavigationAction {
    // 跳转请求
    fileprivate let _request: URLRequest
    override var request: URLRequest {
        return self._request
    }

    // 跳转请求框架
    fileprivate let _sourceFrame: WKFrameInfo
    override var sourceFrame: WKFrameInfo {
        return self._sourceFrame
    }

    // 目标框架
    fileprivate let _targetFrame: WKFrameInfo?
    override var targetFrame: WKFrameInfo? {
        return self._targetFrame
    }

    // 触发跳转的操作类型
    fileprivate let _navigationType: WKNavigationType
    override var navigationType: WKNavigationType {
        return self._navigationType
    }
    
    // 初始化方法
    init(request: URLRequest, sourceFrame: WKFrameInfo, targetFrame: WKFrameInfo?, navigationType: WKNavigationType) {
        self._request = request
        self._sourceFrame = sourceFrame
        self._targetFrame = targetFrame
        self._navigationType = navigationType
        super.init()
    }
}
