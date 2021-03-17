import Foundation
import JavaScriptCore
import PromiseKit

/// The wrapper around JSContext that actually runs the ServiceWorker code. We keep this
/// separate from ServiceWorker itself so that we can create relatively lightwight ServiceWorker
/// classes in response to getRegistration() etc but only create the JS environment when needed.
/// ServiceWorkerExecutionEnvironment 类定义。对 JSContext（JS 执行环境） 的封装，用来执行 service worker 代码
/// 将其与 Service worker 分开的目的在于可以创建轻量级的 service worker 类来响应 getRegistry() 方法，只在需要时创建 JS 执行环境
@objc public class ServiceWorkerExecutionEnvironment: NSObject, ServiceWorkerGlobalScopeDelegate {
    // 声明弱引用 worker 对象
    unowned let worker: ServiceWorker

    // We use this in deinit, by which point the worker is gone
    // 声明常量 workerId，在销毁时使用
    let workerId: String

    /// The heart of it all - this is where our worker code lives.
    /// 私有变量，表示 JS 执行环境
    fileprivate var jsContext: JSContext!

    /// The objects that populate the global scope/self in the worker environment.
    /// 声明 worker 线程的全局作用域
    fileprivate let globalScope: ServiceWorkerGlobalScope

    // 声明 thread 常量
    internal let thread: Thread

    /// Adds setTimeout(), setInterval() etc. to the global scope. We keep a reference at
    /// this level because we need to cancel all timeouts when our execution environment
    /// is being garbage collected.
    /// 声明 timeoutManager 管理类，用来在线程销毁时取消所有计时操作
    fileprivate let timeoutManager: TimeoutManager

    // Since WebSQL connections retain an open connection as long as they are alive, we need to
    // keep track of them, in order to close them off on shutdown. JS garbage collection
    // is sometimes enough, but not always.
    // 声明私有变量，用来收集 WebSQLDatabase 类型的弱引用对象，在断开数据库连接时销毁对象
    // 注：一般 JS 的垃圾回收机制就足够了，但是有时候会有问题
    fileprivate var activeWebSQLDatabases = NSHashTable<WebSQLDatabase>.weakObjects()

    // Various clases that interact with the worker context need a reference to the environment attached to any particular
    // JSContext. So we store that connection here, with weak memory so that they are automatically
    // removed when no longer in use.
    // 在 worker 线程中引用的各种类需要在对应的 JS 执行环境中引用，所以声明 NSMapTable 集合来存储 ServiceWorkerExecutionEnvironment 的弱引用对象
    static var contexts = NSMapTable<JSContext, ServiceWorkerExecutionEnvironment>(keyOptions: NSPointerFunctions.Options.weakMemory, valueOptions: NSPointerFunctions.Options.weakMemory)

    /// We use this at various points to ensure that functions available in a JSContext are called on the right thread.
    /// Right now it'll throw a fatal error if they aren't, to help with debugging, but maybe we can do something better
    /// than that.
    /// 确保在对应的 worker 线程上调用 JSContext 中可用的方法
    /// 根据 JS 执行环境的当前线程，从 contexts 中获取对应 worker 线程，来判断当前 OC 线程与 worker 线程是否一致，不一致则抛出错误
    public static func ensureContextIsOnCorrectThread() {
        let thread = self.contexts.object(forKey: JSContext.current())?.thread
        if thread != Thread.current {
            fatalError("Not executing on context thread")
        }
    }

    // This controls the title that appears in the Safari debugger - helpful to indentify
    // which worker you are looking at when multiple are running at once.
    // 声明 jsContextName 变量，用来获取 JSContext.name，便于 debug 时区分不同的 worker
    var jsContextName: String {
        get {
            return self.jsContext.name
        }
        set(value) {
            self.jsContext.name = value
        }
    }

    // 初始化方法
    @objc public init(_ worker: ServiceWorker) throws {
        self.worker = worker
        self.workerId = worker.id

        // 赋值 thread 为当前线程
        self.thread = Thread.current

        // This shows up in the XCode debugger, helps us to identify the worker thread
        self.thread.name = "ServiceWorker:" + self.workerId

        // Haven't really profiled the difference, but this seems like the category that makes
        // the most sense for a worker
        // 权重为 QualityOfService.utility
        self.thread.qualityOfService = QualityOfService.utility

        // 新建 JS 执行环境
        self.jsContext = JSContext()

        self.globalScope = try ServiceWorkerGlobalScope(context: self.jsContext, worker)
        self.timeoutManager = TimeoutManager(for: Thread.current, in: self.jsContext)

        super.init()

        // We keep track of the Context -> ExecEnvironment mapping for the static ensure call
        // 将 self、jsContext 添加到 contexts 集合中
        ServiceWorkerExecutionEnvironment.contexts.setObject(self, forKey: self.jsContext)

        // 通过 jsContext.exceptionHandler 来捕获 JS 执行环境抛出的异常，传递给 currentException
        self.jsContext.exceptionHandler = { [unowned self] (_: JSContext?, error: JSValue?) in
            // Thrown errors don't error on the evaluateScript call (necessarily?), so after
            // evaluating, we need to check whether there is a new exception.
            // unowned is *required* to avoid circular references that mean this never gets garbage
            // collected
            self.currentException = error
        }

        // 设置 globalScope.delegate = self
        self.globalScope.delegate = self
    }

    // 开启 Runloop，通过开启 Runloop 循环来确保 worker 线程无限运行
    @objc func run() {
        // 检查线程是否是 worker 线程
        self.checkOnThread()

        // I'm not super sure about all of this (need to read more) but this seems to do what we need - keeps
        // the worker thread alive by running RunLoop.current inside the worker thread. This function does not
        // return, as CFRunLoopRun() loops infinitely.
        CFRunLoopRun()
    }

    // 停止 Runloop，与开启 Runloop 循环配对使用
    @objc func stop() {
        // 先检查线程是否是 worker 线程
        self.checkOnThread()

        // ...until we run stop() - CFRunLoopStop() kills the current run loop and allows the run() function
        // above to successfully return
        Log.info?("Stopping run loop for worker thread...")
        CFRunLoopStop(CFRunLoopGetCurrent())
    }

    /// Sometimes we want to make sure that our worker has finished all execution before
    /// we shut it down. Need to flesh this out a lot more (what about timeouts?) but for now
    /// it ensures that all WebSQL databases clean up after themselves on close.
    @objc func ensureFinished(responsePromise: PromisePassthrough) {
        let allWebSQL = self.activeWebSQLDatabases.allObjects

        if allWebSQL.count == 0 {
            return responsePromise.fulfill(())
        }
        Log.info?("Waiting until \(allWebSQL.count) WebSQL connections close before we stop.")
        let mappedClosePromises = allWebSQL.map { $0.close() }

        when(fulfilled: mappedClosePromises)
            .done {
                Log.info?("Closed WebSQL connections")
            }
            .passthrough(responsePromise)
    }

    // 注销
    deinit {
        Log.info?("Closing execution environment for: \(self.workerId)")
        
        // 获取所有已打开的数据库连接对象，逐一关闭
        let allWebSQL = self.activeWebSQLDatabases.allObjects
            .filter { $0.connection.open == true }

        if allWebSQL.count > 0 {
            Log.info?("\(allWebSQL.count) open WebSQL connections when shutting down worker")
        }

        allWebSQL.forEach { $0.forceClose() }

        // 注销全局 JSContext 对象；currentException 置为空；停止所有计时操作；jsContext.exceptionHandler 置为空
        GlobalVariableProvider.destroy(forContext: self.jsContext)
        self.currentException = nil
        self.timeoutManager.stopAllTimeouts = true
        self.jsContext.exceptionHandler = nil
        
        // 禁止堆栈、寄存器、js 执行环境等收集 JavaScript value，释放内存
        JSGarbageCollect(self.jsContext.jsGlobalContextRef)
    }

    // Thrown errors don't error on the evaluateScript call (necessarily?), so after
    // evaluating, we need to check whether there is a new exception.
    // 声明 JSValue 类型的变量，用来标记 JS 执行环境抛出的异常
    internal var currentException: JSValue?

    // 如果捕获到异常，则抛出错误信息，通过自定义 ErrorMessage（转换 JSValue 类型为 Swift 类型）
    fileprivate func throwExceptionIfExists() throws {
        if let exc = currentException {
            self.currentException = nil
            throw ErrorMessage("\(exc)")
        }
    }

    /// Similar to the ensureOnCurrentThread() static function, this is here to make sure that the calls
    /// we run from ServiceWorker by calling NSObject.perform() are actually being run on the correct thread.
    // 线程检查，用来判断 ServiceWorker 类中调用 NSObject.perform() 的目标线程是否是 worker 线程
    fileprivate func checkOnThread() {
        if Thread.current != self.thread {
            fatalError("Tried to execute worker code outside of worker thread")
        }
    }

    /// Actually run some JavaScript inside the worker context. evaluateScript() itself is
    /// synchronous, but ServiceWorker calls it without waiting for response (because this
    /// thread could be frozen) so we use the EvaluateScriptCall wrapper to asynchronously
    /// send back the response.
    /// 在 JS 执行环境中运行 JS 脚本。
    /// 因为 evaluateScript() 方法是同步的，但是 worker 调用此方法时不需要等待响应信息，所以使用 EvaluateScriptCall 来异步返回响应信息
    /// 先检查线程是否是 worker 线程，即调用 checkOnThread()
    /// 先判断 currentException 是否为空；实例化 jsContext.evaluateScript() 对象；尝试捕获异常，若有则触发 fulfill 回调
    /// 若无异常，则获取到响应信息后，判断其类型，触发 fulfill，返回响应信息
    @objc func evaluateScript(_ call: EvaluateScriptCall) {
        self.checkOnThread()

        do {
            if self.currentException != nil {
                throw ErrorMessage("Cannot run script while context has an exception")
            }

            let returnJSValue = self.jsContext.evaluateScript(call.script, withSourceURL: call.url)

            try self.throwExceptionIfExists()

            guard let returnExists = returnJSValue else {
                call.fulfill(nil)
                return
            }

            if call.returnType == .promise {
                call.fulfill(JSContextPromise(jsValue: returnExists, thread: self.thread))
            } else if call.returnType == .void {
                call.fulfill(nil)
            } else {
                call.fulfill(returnExists.toObject())
            }

        } catch {
            call.reject(error)
        }
    }

    // 打开 WebSQL 数据库，ServiceWorkerGlobalScopeDelegate 代理方法
    // 先检查线程是否是 worker 线程，即调用 checkOnThread()
    // 打开数据库，将其弱引用对象添加到 activeWebSQLDatabases 集合中，返回数据库对象
    func openWebSQLDatabase(name: String) throws -> WebSQLDatabase {
        self.checkOnThread()
        let db = try WebSQLDatabase.openDatabase(for: self.worker, in: self, name: name)

        // WebSQL connections stay open until they are garbage collected, so we need to manually
        // shut them down when the worker is done. We add to keep track of active DBs:

        self.activeWebSQLDatabases.add(db)
        return db
    }

    /// Importing scripts is relatively complicated because it involves freezing the worker
    /// thread entirely while we fetch the contents of our scripts. We use a DispatchSemaphore
    /// to do that, while running our delegate function on another queue.
    /// 导入脚本，ServiceWorkerGlobalScopeDelegate 代理方法
    /// 导入脚本相对比较复杂，因为在读取脚本内容的时候会阻塞整个 worker 线程。这里使用 DispatchSemaphore 来阻塞线程，并在另一个任务队列中执行代理方法
    /// 先检查线程是否是 worker 线程，即调用 checkOnThread()
    /// 获取 url 数组第一个元素。此处时间实际上是在循环遍历数组，反复调用importScripts()，每次删除一个URL。这样做的主要原因是保持内存低占有率——理论上这些JS文件可能有数百KB大，所以我们不能将它们全部加载到内存中，而只是一次加载一个。
    /// 判断代理方法是否实现，若未实现，则抛出异常
    /// 创建 DispatchSemaphore(value: 0) 信号量
    /// 声明 error、content，用来存储代理方法的执行结果来返回给当前 JSContext
    /// 获取队列，异步执行代理方法（即查询 worker_imported_scripts 表获取 sw.js 内容），获取 error 或 content，发送信号，唤醒线程
    /// 发送信号量开始等待(继续的信号量在上一步的异步线程中发送)
    /// 接收到 error 或 content，开始判断，若 error 不为空，则抛出异常
    /// 若 content 不为空，则调用 jsContext.evaluateScript() 执行脚本，如果捕获 JS 线程发送的异常则进行处理，否则删除此 url，循环调用 importScripts()
    func importScripts(urls: [URL]) throws {
        self.checkOnThread()

        // We actually loop through the URL array, calling importScripts() over and over, removing
        // a URL each time. The main reason for doing this is to keep memory usage low - in theory
        // these JS files could be hundreds of KB big, so rather than load them all into memory
        // we just do them one at a time.

        guard let url = urls.first else {
            // We've finished the array
            return
        }

        // It's possible that our delegate doesn't implement script imports. If so we throw out
        // immediately

        guard let loadFunction = self.worker.delegate?.serviceWorker else {
            throw ErrorMessage("Worker delegate does not implement importScripts")
        }

        // This is what controls out thread freezing.

        let semaphore = DispatchSemaphore(value: 0)

        // Because we're going to execute the load function asynchoronously on another
        // queue, we need to have a way of passing the results back to our current context.
        // So, we declare these variables to store the results in:

        var error: Error?
        var content: String?

        // Now we spin off a new dispatch queue and run out load function in it:

        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            loadFunction(self.worker, url) { err, body in
                if err != nil {
                    error = err
                } else {
                    content = body
                }

                // This call resumes our thread. But because this is asynchronous, this
                // line will run after...

                semaphore.signal()
            }
        }

        // ...this one, which contains the command to freeze our main thread.

        semaphore.wait()

        // at this point our async function has executed and stored its results in the
        // variables we created. Now we act on those variables:

        if let err = error {
            throw err
        } else if let hasContent = content {
            // Provide our import has run successfully, we can now actually evaluate
            // the script. withSourceURL means that the source in Safari debugger will
            // be attributed correctly.

            self.jsContext.evaluateScript(hasContent, withSourceURL: url)

            if let exception = self.jsContext.exception {
                // If an error occurred in the process of importing the script,
                // bail out

                throw ErrorMessage("\(exception)")
            }

            // Now that we've successfully imported this script, we remove it from our
            // array of scripts and run again.

            var mutableURLs = urls
            mutableURLs.removeFirst(1)
            return try self.importScripts(urls: mutableURLs)

        } else {
            // It's actually possible for a faulty delegate to return neither an error
            // nor a result. So we need to factor that in.

            throw ErrorMessage("importScripts loader did not return content, but did not return an error either")
        }
    }

    /// We want to run our JSContext on its own thread, but every now and then we need to
    /// manually manipulate JSValues etc, so we can't use evaluateScript() directly. Instead,
    /// this lets us run a (synchronous) piece of code on the correct thread.
    /// 在自己的线程上运行 JSContext，需要时不时的手动操作 JSValues 等，所以不能直接使用 evaluateScript()。相反，这样保证了我们的代码段运行在正确的线程上
    /// 先检查线程是否是 worker 线程，即调用 checkOnThread()
    /// 调用 WithJSContextCall.funcToRun()，触发 fulfill 或 reject 回调
    @objc internal func withJSContext(_ call: WithJSContextCall) {
        self.checkOnThread()
        do {
            try call.funcToRun(self.jsContext)
            call.seal.fulfill(())
        } catch {
            call.seal.reject(error)
        }
    }

    /// Send an event (of any kind, ExtendableEvent etc.) into the worker. This is the way
    /// the majority of triggers are set in the worker context. Like evaluateScript, it must
    /// be called on the worker thread, which ServiceWorker does.
    /// 分发事件到 worker 线程，即在 worker 线程中设置触发器，功能类似 evaluateScript，必须在 worke 线程中调用
    /// 先检查线程是否一致，即调用 checkOnThread()，确保在 worker 线程中
    /// 调用 globalScope.dispatchEvent 分发事件，并判断是否捕获异常，触发回调
    @objc func dispatchEvent(_ call: DispatchEventCall) {
        self.checkOnThread()
        self.globalScope.dispatchEvent(call.event)

        do {
            try self.throwExceptionIfExists()
            call.seal.fulfill(nil)
        } catch {
            call.seal.reject(error)
        }
    }

    /// fetch() can be run with either a string or a full Request object. This separates them
    /// out, as well as parsing strings to native URL objects.
    /// 请求资源
    /// 参数为 string 或完整的 request 对像
    /// firstly：创建 request 对象，如果参数是 string 类型，则转换成 URL 后再构建 request 对象，发起请求
    /// 将 response 转换为 JS Promise 对象返回
    func fetch(_ requestOrString: JSValue) -> JSValue? {
        return firstly { () -> Promise<FetchResponseProtocol> in

            var request: FetchRequest

            if let fetchInstance = requestOrString.toObjectOf(FetchRequest.self) as? FetchRequest {
                request = fetchInstance
            } else if requestOrString.isString {
                guard let requestString = requestOrString.toString() else {
                    throw ErrorMessage("Could not convert request to string")
                }

                guard let parsedURL = URL(string: requestString) else {
                    throw ErrorMessage("Could not parse URL string")
                }

                request = FetchRequest(url: parsedURL)
            } else {
                throw ErrorMessage("Did not understand first argument passed in")
            }

            return FetchSession.default.fetch(request, fromOrigin: self.worker.url)

        }.toJSPromiseInCurrentContext()
    }

    /// Part of the Service Worker spec: https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/skipWaiting
    /// is fired during install events to make sure the worker takes control of its scope immediately.
    /// 跳过等待状态，用来直接激活 worker
    /// 设置 worker.skipWaitingStatus = true
    func skipWaiting() {
        self.worker.skipWaitingStatus = true
    }
}
