import Foundation

// Log 结构体声明
public struct SharedLogInterface {
    public var debug: ((String) -> Void)?
    public var info: ((String) -> Void)?
    public var warn: ((String) -> Void)?
    public var error: ((String) -> Void)?
}

// We want to be able to plug in a custom logging interface depending on environment.
// This var is here for quick access inside the SW code (Log?.info()), but can be set
// via ServiceWorker.logInterface in external code.
// 用来快速访问 log 方法
public var Log = SharedLogInterface(debug: nil, info: nil, warn: nil, error: nil)
