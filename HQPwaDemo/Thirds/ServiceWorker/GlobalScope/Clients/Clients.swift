import Foundation
import JavaScriptCore
import PromiseKit

// 遵循 JSExport 协议，提供 Clients 方法及属性给 js 调用
@objc protocol ClientsExports: JSExport {
    func get(_: String) -> JSValue?
    func matchAll(_: [String: Any]?) -> JSValue?
    func openWindow(_: String) -> JSValue?
    func claim() -> JSValue?
}

/// Implementation of Clients: https://developer.mozilla.org/en-US/docs/Web/API/Clients to allow
/// Service Workers to get/take control of/open clients under their scope. This is really just
/// a bridge to whatever ServiceWorkerClientDelegate is set.
/// Clients API 实现，用来允许 Service Workers 在其作用域下 获取/控制/打开 client。这其实是一个桥接类，用来实现 ServiceWorkerClientDelegate 方法
/// Client 代表一个可执行上下文，例如一个 Worker 或 SharedWorker
@objc class Clients: NSObject, ClientsExports {
    // 声明 worker，类型为 ServiceWorker
    unowned let worker: ServiceWorker

    // 初始化方法，赋值 worker
    init(for worker: ServiceWorker) {
        self.worker = worker
    }

    // 根据 id 来获取 service worker client，并包装为 Promise 对象返回
    func get(_ id: String) -> JSValue? {
        return Promise<Client?> { seal in
            if self.worker.clientsDelegate?.clients?(self.worker, getById: id, { err, clientProtocol in
                if let error = err {
                    seal.reject(error)
                } else if let clientExists = clientProtocol {
                    seal.fulfill(Client.getOrCreate(from: clientExists))
                } else {
                    seal.fulfill(nil)
                }
            }) == nil {
                seal.reject(ErrorMessage("ServiceWorkerDelegate does not implement get()"))
            }
        }.toJSPromiseInCurrentContext()
    }

    // 返回所有包含可选参数的 service worker client 对象数组
    func matchAll(_ options: [String: Any]?) -> JSValue? {
        return Promise<[Client]> { seal in

            // Two options provided here: https://developer.mozilla.org/en-US/docs/Web/API/Clients/matchAll
            
            // 设置匹配类型，默认为 "all"
            let type = options?["type"] as? String ?? "all"
            // 设置匹配范围，默认为 false，即只匹配当前 service worker 控制的 client
            let includeUncontrolled = options?["includeUncontrolled"] as? Bool ?? false

            // 构建 ClientMatchAllOptions 对象
            let options = ClientMatchAllOptions(includeUncontrolled: includeUncontrolled, type: type)

            // MARK: - ServiceWorkerClientsDelegate - matchAll 方法实现
            if self.worker.clientsDelegate?.clients?(self.worker, matchAll: options, { err, clientProtocols in
                if let error = err {
                    seal.reject(error)
                } else if let clientProtocolsExist = clientProtocols {
                    let mapped = clientProtocolsExist.map { Client.getOrCreate(from: $0) }
                    seal.fulfill(mapped)
                } else {
                    seal.reject(ErrorMessage("Callback did not error but did not send a response either"))
                }
            }) == nil {
                seal.reject(ErrorMessage("ServiceWorkerDelegate does not implement matchAll()"))
            }
        }
        .toJSPromiseInCurrentContext()
    }

    // Clients 的 openWindow 方法。用来创建一个顶级的 webview 线程来加载传入的 URL，如果执行时提示没有权限，则抛出 InvalidAccessError
    func openWindow(_ url: String) -> JSValue? {
        return Promise<ClientProtocol> { seal in
            guard let parsedURL = URL(string: url, relativeTo: self.worker.url) else {
                return seal.reject(ErrorMessage("Could not parse URL given"))
            }

            // MARK: - ServiceWorkerClientsDelegate - openWindow 方法实现
            if self.worker.clientsDelegate?.clients?(self.worker, openWindow: parsedURL, { err, resp in
                if let error = err {
                    seal.reject(error)
                } else if let response = resp {
                    seal.fulfill(response)
                }
            }) == nil {
                seal.reject(ErrorMessage("ServiceWorkerDelegate does not implement openWindow()"))
            }
        }.toJSPromiseInCurrentContext()
    }

    // 用来允许激活的 service worker 设置其为作用域内所有 client 的控制器，这将触发 navigator.serviceWorker 的 "controllerchange" 事件，所有 clients 中的 serviceworker 将被此 service worker 控制
    // 当首次注册加载时，pages 不能调用此方法，只有在重新加载时才可以。注意：此方法将导致 service worker 控制 pages 的加载
    func claim() -> JSValue? {
        return Promise<Void> { seal in
            // MARK: - ServiceWorkerClientsDelegate - clientsClaim 方法实现
            if self.worker.clientsDelegate?.clientsClaim?(self.worker, { err in
                if let error = err {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            }) == nil {
                seal.reject(ErrorMessage("ServiceWorkerDelegate does not implement claim()"))
            }
        }.toJSPromiseInCurrentContext()
    }
}
