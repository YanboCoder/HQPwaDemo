import Foundation

/// Storage specific hooks for a worker. Should rename to ServiceWorkerStorageDelegate at
/// some point.
/// ServiceWorkerDelegate 协议声明
@objc public protocol ServiceWorkerDelegate {
    @objc func serviceWorker(_: ServiceWorker, importScript: URL, _ callback: @escaping (Error?, String?) -> Void)
    @objc func serviceWorkerGetDomainStoragePath(_: ServiceWorker) throws -> URL
    @objc func serviceWorkerGetScriptContent(_: ServiceWorker) throws -> String
    @objc func getCoreDatabaseURL() -> URL
}
