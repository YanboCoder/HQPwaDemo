import Foundation

/// On the web this is for MessagePorts, ImageBitmaps and ArrayBuffers
/// but for now we're just focusing on MessagePorts. Getting things like
/// ArrayBuffers into SWWebView will be a pain, but not impossible. SharedArrayBuffers
/// probably are impossible, though.
/// Transferable 协议定义。
/// 可转移接口表示一个可以在不同执行上下文(如主线程和 Web worker )之间转移的对象
/// 这是一个抽象接口，并且没有这种类型的对象
/// 这个接口没有定义任何方法或属性；它只是一个标记，指示在特定条件下可以使用的对象
/// 例如使用 Worker. postmessage() 方法将对象传递给 Worker
/// ArrayBuffer，MessagePort，ImageBitmap 和 OffscreenCanvas 类型实现了这个接口
/// 我们主要在 MessagePorts 中实现
/// ArrayBuffers 在 SWWebView 中也可以实现，但是比较难；其他的不太可能
@objc public protocol Transferable {}
