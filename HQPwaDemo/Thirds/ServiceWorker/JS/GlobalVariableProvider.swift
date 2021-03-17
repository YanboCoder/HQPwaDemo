import Foundation
import JavaScriptCore

// I'm seeing weird issues with memory holds when we add objects directly to a
// JSContext's global object. So instead we use this and defineProperty to map
// properties without directly attaching them to the object.
// 当我们直接将对象添加到 JSContext 的全局对象时，存在一些奇怪的内存持有问题。因此，我们使用 this 和 defineProperty 来映射属性，而不直接将它们附加到对象。
class GlobalVariableProvider {
    // 初始化 variableMaps
    static let variableMaps = NSMapTable<JSContext, NSMutableDictionary>(keyOptions: NSPointerFunctions.Options.weakMemory, valueOptions: NSPointerFunctions.Options.strongMemory)

    // 获取指定 JSContext 中保存的对象
    fileprivate static func getDictionary(forContext context: JSContext) -> NSDictionary {
        if let existing = variableMaps.object(forKey: context) {
            return existing
        }

        let newDictionary = NSMutableDictionary()
        variableMaps.setObject(newDictionary, forKey: context)
        return newDictionary
    }

    // 创建属性的 getter 方法
    fileprivate static func createPropertyAccessor(for name: String) -> @convention(block) () -> Any? {
        return {
            guard let ctx = JSContext.current() else {
                Log.error?("Tried to use a JS property accessor with no JSContext. Should never happen")
                return nil
            }

            let dict = GlobalVariableProvider.getDictionary(forContext: ctx)
            return dict[name]
        }
    }

    // 销毁指定的 JSContext 中添加的对象
    static func destroy(forContext context: JSContext) {
        if let dict = variableMaps.object(forKey: context) {
            // Not really sure if this makes a difference, but we might as well
            // delete the property callbacks we created.
            dict.allKeys.forEach { key in
                if let keyAsString = key as? String {
                    context.globalObject.deleteProperty(keyAsString)
                }
            }
        }

        if context.globalObject.hasProperty("self") {
            context.globalObject.deleteProperty("self")
        }

        self.variableMaps.removeObject(forKey: context)
    }

    /// A special case so we don't need to hold a reference to the global object
    /// 这是一种特殊情况，因此我们不需要保存对全局对象的引用
    /// 添加 self 到 JSContext 中
    static func addSelf(to context: JSContext) {
        context.globalObject.defineProperty("self", descriptor: [
            "get": {
                JSContext.current().globalObject
            } as @convention(block) () -> Any?
        ])
    }

    // 添加变量名、变量到 JSContext 中
    static func add(variable: Any, to context: JSContext, withName name: String) {
        let dictionary = GlobalVariableProvider.getDictionary(forContext: context)
        dictionary.setValue(variable, forKey: name)

        context.globalObject.defineProperty(name, descriptor: [
            "get": createPropertyAccessor(for: name)
        ])
    }

    // 添加错误信息到 JSContext 中
    static func add(missingPropertyWithError error: String, to context: JSContext, withName name: String) {
        context.globalObject.defineProperty(name, descriptor: [
            "get": {
                if let ctx = JSContext.current() {
                    let err = JSValue(newErrorFromMessage: error, in: ctx)
                    ctx.exception = err
                }
            } as @convention(block) () -> Void
        ])
    }
}
