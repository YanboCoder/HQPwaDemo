//
//  YBRootViewController.swift
//  HQPwaDemo
//
//  Created by wang on 2021/3/12.
//

import UIKit
import WebKit
import PromiseKit
import JavaScriptCore

@objc protocol YBWebViewProtocol: JSExport {
    func fullName()
}

@objc class YBWebViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate, WKScriptMessageHandler, YBWebViewProtocol {
    var addressBar: UITextField?
    var wkWebView: WKWebView = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .lightGray
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))
        
        self.setupTextField()
        self.setupWebView()
    }
    
    func setupTextField() {
        let addressBar = UITextField(frame: CGRect(x: 0, y: 84, width: self.view.bounds.width, height: 60))
        addressBar.text = "https://yanboCoder.github.io/pwa-demos/simplepwa/"
        addressBar.borderStyle = .roundedRect
        addressBar.placeholder = "请输入资源地址"
        addressBar.delegate = self
        addressBar.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 60))
        addressBar.leftViewMode = .always
        
        self.view.addSubview(addressBar)
        self.addressBar = addressBar
    }
    
    func setupWebView() {
        let pathToJS = Bundle(for: SWWebView.self).bundleURL
            .appendingPathComponent("js-dist", isDirectory: true)
            .appendingPathComponent("CustomRuntime.js")
        let jsRuntimeSource: String
        do {
            jsRuntimeSource = try String(contentsOf: pathToJS)
        } catch {
            Log.error?("Could not load SWWebKit runtime JS. Quitting.")
            fatalError()
        }
        let userScript = WKUserScript(source: jsRuntimeSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        let webView: WKWebView = WKWebView.init(frame: CGRect(x: 0, y: 144, width: self.view.bounds.width, height: self.view.bounds.height-144))
        webView.navigationDelegate = self
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(self, name: "foo")
        let  url = NSURL(string: "https://yanboCoder.github.io/pwa-demos/simplepwa/")
        let request = URLRequest(url: url! as URL)
        webView .load(request)
        self.view.addSubview(webView)
        self.wkWebView = webView
    }
    
    @objc private func refresh() {
        let context = JSContext()
        let webVC = YBWebViewController()
        context?.setObject(webVC, forKeyedSubscript: NSString(string:"webVC"))
        context?.evaluateScript("webVC.fullName()")
    }
    
    func fullName() {
        print("===== fullName =====")
    }
    
    // MARK: - UITextFieldDelegate -
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        let urlString = textField.text! as String
        
        guard let urlComps = URLComponents(string: urlString) else {
            fatalError("must provide a valid url")
        }

        URLCache.shared.removeAllCachedResponses()
        print("Loading \(urlComps.url!.absoluteString)")
        _ = self.wkWebView.load(URLRequest(url: urlComps.url!))
        
        return true
    }
    
    // MARK: - WKScriptMessageHandler -
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        firstly { () -> Promise<Any?> in
            
            print("=== userContentController ===\n" + "Name: \(message.name)\n" + "Body: \(message.body)")

            return Promise.value(nil)

        }.catch { error in
            Log.error?("Failed to parse API request: \(error)")
        }
    }
    
    // MARK: - WKNavigationDelegate -
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        print("=== decidePolicyFor navigationAction ===\n \(navigationAction.request)")
        return decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
//        print("=== decidePolicyFor navigationResponse ===\n \(navigationResponse.response)")
        return decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
//        print("=== didCommit ===\n \(String(describing: webView.url))")
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        print("=== didStartProvisionalNavigation ===\n \(String(describing: webView.url))")
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
//        print("=== didReceiveServerRedirectForProvisionalNavigation ===\n \(String(describing: webView.url))")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        print("=== didFail ===\n \(String(describing: webView.url))")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        print("=== didFailProvisionalNavigation ===\n \(String(describing: webView.url))")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        print("=== didFinish ===\n \(String(describing: webView.url))")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
//        print("=== webViewWebContentProcessDidTerminate ===\n \(String(describing: webView.url))")
    }
}
