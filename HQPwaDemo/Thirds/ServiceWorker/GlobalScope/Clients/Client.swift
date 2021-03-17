import Foundation
import JavaScriptCore

// 遵循 JSExport 协议，提供 Client 方法及属性给 js 调用
@objc protocol ClientExports: JSExport {
    func postMessage(_ toSend: JSValue, _ transferrable: [JSValue])
    var id: String { get }
    var type: String { get }
    var url: String { get }
}

/// An implementation of the Client API: https://developer.mozilla.org/en-US/docs/Web/API/Client
/// mostly a wrapper around an external class that implements ClientProtocol.
/// Client API 实现，主要是实现对扩展类 ClientProtocol 的包装
@objc class Client: NSObject, ClientExports {
    // We keep track of the client objects we've made before now, so that we
    // pass the same instances back into JSContexts where relevant. That means
    // they'll pass equality checks etc.
    // We don't want strong references though - if the JSContext is done with
    // a reference it doesn't have anything to compare to, so it can be garbage collected.
    // 初始化 existingClients 集合，用来追踪 client 对象；保存其弱引用对象，以便于自动释放
    fileprivate static var existingClients = NSHashTable<Client>.weakObjects()

    // 获取或创建 client
    static func getOrCreate<T: ClientProtocol>(from wrapper: T) -> Client {
        return self.existingClients.allObjects.first(where: { $0.clientInstance.id == wrapper.id }) ?? {
            let newClient = { () -> Client in

                // We could pass back either a Client or the more specific WindowClient - we need
                // our bridging class to match the protocol being passed in.
                // 需要根据传入的 wrapper 所遵循的协议来返回相应的对象，即 Client 或 WindowClient
                if let windowWrapper = wrapper as? WindowClientProtocol {
                    return WindowClient(wrapping: windowWrapper)
                } else {
                    return Client(client: wrapper)
                }
            }()

            // 添加 client 到 existingClients 集合中
            self.existingClients.add(newClient)
            return newClient
        }()
    }

    // 声明 clientInstance，类型为 ClientProtocol
    let clientInstance: ClientProtocol
    
    // 初始化方法，对 clientInstance 赋值
    internal init(client: ClientProtocol) {
        self.clientInstance = client
    }

    // MARK: - ClientExports 方法及属性实现 -
    // 调用相应的 ClientProtocol 方法，具体实现在 ServiceWorkerContainer 中
    // 允许一个 service worker 对象发送消息到 client（a Window, Worker, or SharedWorker）。在 navigator.serviceWorker 的 message 事件中接收消息
    func postMessage(_ toSend: JSValue, _: [JSValue]) {
        self.clientInstance.postMessage(message: toSend.toObject(), transferable: nil)
    }

    // client 的唯一标识符
    var id: String {
        return self.clientInstance.id
    }

    // client 对象类型
    var type: String {
        return self.clientInstance.type.stringValue
    }

    // client 的 URL
    var url: String {
        return self.clientInstance.url.absoluteString
    }
}
