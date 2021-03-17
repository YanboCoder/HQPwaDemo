import Foundation
import JavaScriptCore

/// We need a little help with ArrayBuffers because they require us to maintain
/// a reference to the Data contained within them, otherwise the reference is
/// lost and the data overwritten.
/// 我们需要一些 arraybuffer 的帮助，因为它们要求我们维护对包含在其中的数据的引用，
/// 否则引用会丢失，数据会被覆盖。
class JSArrayBuffer: NSObject {
    /// We keep track of all the JSArrayBuffer instances that have been made
    /// and not yet deallocated. This means we never lose references to the data
    /// an array buffer is using.
    /// 初始化 currentInstances 集合，保持对未释放的 JSArrayBuffer 对象的强引用
    fileprivate static var currentInstances = Set<JSArrayBuffer>()

    // The actual mutable the array buffer stores data in
    // 声明 data，用来存放数据
    var data: Data

    /// This is called by the ArrayBuffer deallocator - set in make()
    /// 这个方法在销毁时调用
    static func unassign(bytes _: UnsafeMutableRawPointer?, reference: UnsafeMutableRawPointer?) {
        guard let existingReference = reference else {
            Log.error?("Received deallocate message from a JSArrayBuffer with no native reference")
            return
        }

        let jsb = Unmanaged<JSArrayBuffer>.fromOpaque(existingReference).takeUnretainedValue()
        JSArrayBuffer.currentInstances.remove(jsb)
        Log.info?("Unassigning JSArrayBuffer memory: \(jsb.data.count) bytes")
    }

    // fileprivate becuase we don't ever want to make one of these without wrapping it
    // in the JSContext ArrayBuffer, as done in make()
    // 私有初始化方法，用来确保只有在使用 JSContext ArrayBuffer 时才可创建
    fileprivate init(from data: Data) {
        self.data = data
        super.init()
    }

    // 
    static func make(from data: Data, in context: JSContext) -> JSValue {
        let instance = JSArrayBuffer(from: data)

        // create a strong reference to this data
        JSArrayBuffer.currentInstances.insert(instance)

        // the deallocator can't store a reference to the instance directly, instead
        // we pass a pointer into the Array Buffer constructor which is then passed back
        // when the deallocator is run.
        let instancePointer = Unmanaged.passUnretained(instance).toOpaque()

        // NOTE: Fixed an unclear issue around ArrayBuffer

        let ptr: UnsafeMutableBufferPointer<UInt8> = .allocate(capacity: data.count)

        instance.data.withUnsafeBytes { (contentsPrt: UnsafePointer<UInt8>) -> Void in
            _ = ptr.initialize(from: UnsafeBufferPointer(start: contentsPrt, count: data.count))
        }
        var exception: JSValueRef?

        let deallocator: JSTypedArrayBytesDeallocator = { ptr, reference in
            JSArrayBuffer.unassign(bytes: ptr, reference: reference)
            ptr?.deallocate()
        }

        let arrayBuffJSRef = JSObjectMakeArrayBufferWithBytesNoCopy(
            context.jsGlobalContextRef,
            ptr.baseAddress,
            data.count,
            deallocator,
            instancePointer,
            &exception)

        if exception != nil {
            context.exception = JSValue(jsValueRef: exception, in: context)
            return JSValue(jsValueRef: nil, in: context)
        }

        return JSValue(jsValueRef: arrayBuffJSRef, in: context)

        /* // Since the following implemtantion always responses wrong data.

        // Now we make our actual array buffer JSValue using the data and deallocation callback
        let jsInstance = instance.data.withUnsafeMutableBytes { pointer -> JSObjectRef in

            JSObjectMakeArrayBufferWithBytesNoCopy(context.jsGlobalContextRef, pointer, data.count, { bytes, reference in
                JSArrayBuffer.unassign(bytes: bytes, reference: reference)
            }, instancePointer, nil)
        }

        return JSValue(jsValueRef: jsInstance, in: context)
         */
    }
}
