import Foundation
import JavaScriptCore

/// This is primarily used to bridge between ServiceWorkerGlobalScope and ServiceWorkerExecutionEnvironment
/// without having to make a reference loop between then. Leaves open possibility for other delegate
/// implementations, though.
/// 协议类声明，用于 ServiceWorkerGlobalScope 和 ServiceWorkerExecutionEnvironment 之间建立联系
@objc protocol ServiceWorkerGlobalScopeDelegate {
    func importScripts(urls: [URL]) throws
    func openWebSQLDatabase(name: String) throws -> WebSQLDatabase
    func fetch(_: JSValue) -> JSValue?
    func skipWaiting()
}
