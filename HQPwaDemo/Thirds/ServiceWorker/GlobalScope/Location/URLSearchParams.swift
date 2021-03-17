import Foundation
import JavaScriptCore

// 遵循 JSExport 协议，提供 URLSearchParams 方法及属性给 js 调用
@objc public protocol URLSearchParamsExport: JSExport {
    func append(_: String, _: String)
    func delete(_: String)
    func entries(_: String) -> JSValue?
    func get(_: String) -> String?
    func getAll(_: String) -> [String]
    func has(_: String) -> Bool
    func keys(_: String) -> JSValue?
    func set(_: String, _: String)
    func sort()
    func toString() -> String
    func values() -> JSValue?
}

/// Quick implementation of URLSearchParams: https://developer.mozilla.org/en-US/docs/Web/API/URL/searchParams
/// does not store any information internally, just sets and gets from the underlying URLComponents.
/// URLSearchParams 类的实现，用来从 URLComponents 中获取或设置查询参数
@objc public class URLSearchParams: NSObject, URLSearchParamsExport {
    // 声明 components，类型为 URLComponents，用来解析或构造 URLs
    var components: URLComponents

    // 初始化方法，components 赋值
    init(components: URLComponents) {
        self.components = components
        super.init()
    }

    // 获取 components 的查询项数组，按照其在原始查询字符串中出现的顺序
    fileprivate var queryItems: [URLQueryItem] {
        get {
            if let q = self.components.queryItems {
                return q
            }

            let arr: [URLQueryItem] = []
            self.components.queryItems = arr
            return arr
        }

        set(val) {
            self.components.queryItems = val
        }
    }

    // 将指定的键值对追加到搜索参数中
    public func append(_ name: String, _ value: String) {
        self.queryItems.append(URLQueryItem(name: name, value: value))
    }

    // 从搜索参数列表中删除指定的参数所对应的键值对
    public func delete(_ name: String) {
        self.queryItems = self.queryItems.filter { $0.name != name }
    }

    // 转换成迭代器，实现 next(value: JavaScript, down: boolean) 方法
    fileprivate func toIterator(item: Any) -> JSValue? {
        // Probably a better way of doing this but oh well

        guard let context = JSContext.current() else {
            return nil
        }

        return context
            .evaluateScript("(obj) => obj[Symbol.iterator]")
            .call(withArguments: [item])
    }

    // 返回 name 的迭代器，允许迭代该对象中包含的所有键/值对。每对键和值都是 JSValue 对象
    public func entries(_ name: String) -> JSValue? {
        let entriesArray = self.queryItems
            .filter { $0.name == name }
            .map { [$0.name, $0.value] }

        // Probably a better way of doing this but oh well

        return self.toIterator(item: entriesArray)
    }

    // 返回与给定搜索参数相关的第一个值
    public func get(_ name: String) -> String? {
        return self.queryItems.first(where: { $0.name == name && $0.value != nil })?.value
    }

    // 以数组的形式返回与给定搜索参数相关联的所有值
    public func getAll(_ name: String) -> [String] {
        var all: [String] = []

        self.queryItems.forEach { item in
            if item.name == name, let val = item.value {
                all.append(val)
            }
        }

        return all
    }

    // 返回一个布尔值，该值指示具有指定名称的参数是否存在。
    public func has(_ name: String) -> Bool {
        return self.queryItems.first(where: { $0.name == name }) != nil
    }

    // 返回一个迭代器，允许迭代该对象中包含的所有键,键是 JSValue 对象。
    public func keys(_: String) -> JSValue? {
        var keys: [String] = []

        self.queryItems.forEach { item in
            if keys.contains(item.name) == false {
                keys.append(item.name)
            }
        }

        return self.toIterator(item: keys)
    }

    // 将与给定搜索参数关联的值设置为给定值。如果有几个匹配的值，这个方法会删除其他的。如果搜索参数不存在，该方法将创建它。
    public func set(_ name: String, _ value: String) {
        self.delete(name)
        self.append(name, value)
    }

    // 方法的作用是:对该对象中包含的所有键/值对进行排序，并返回未定义的结果
    // 排序顺序根据键的 unicode 代码点，该方法使用稳定的排序算法(即键值相等的键/值对之间的相对顺序将被保留)
    public func sort() {
        self.queryItems = self.queryItems.sorted(by: { $0.name < $1.name })
    }

    // 返回一个适合在 URL 中使用的查询字符串。
    public func toString() -> String {
        return self.components.url?.query ?? ""
    }

    // 返回一个迭代器，允许对该对象中包含的所有值进行迭代，这些值是 JSValue 对象。
    public func values() -> JSValue? {
        let valuesArray = self.queryItems.map { $0.value }

        return self.toIterator(item: valuesArray)
    }
}
