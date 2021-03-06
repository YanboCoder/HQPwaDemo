//
//  WKWebViewController.swift
//  HQPwaDemo
//
//  Created by wang on 2021/2/5.
//

import UIKit
import WebKit
import PromiseKit
import JavaScriptCore

class WKWebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, WKURLSchemeHandler {
    var wkWebView: WKWebView = WKWebView()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "WKWebView"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Back", style: .plain, target: self, action: #selector(back))

        // Do any additional setup after loading the view.
//        let pathToJS = Bundle(for: SWWebView.self).bundleURL
//            .appendingPathComponent("js-dist", isDirectory: true)
//            .appendingPathComponent("CustomRuntime.js")
//        let jsRuntimeSource: String
//        do {
//            jsRuntimeSource = try String(contentsOf: pathToJS)
//        } catch {
//            Log.error?("Could not load SWWebKit runtime JS. Quitting.")
//            fatalError()
//        }
//        let userScript = WKUserScript(source: jsRuntimeSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        let webView: WKWebView = WKWebView.init(frame: self.view.frame)
        webView.navigationDelegate = self
//        webView.configuration.userContentController.addUserScript(userScript)
//        webView.configuration.userContentController.add(self, name: "serviceWorker")
        let  url = NSURL(string: "https://yanboCoder.github.io/pwa-demos/simplepwa/")
        let request = URLRequest(url: url! as URL)
        webView .load(request)
        self.view.addSubview(webView)
        self.wkWebView = webView
    }
    
    @objc private func refresh() {
        wkWebView.reload()
    }
    
    @objc private func back() {
        if wkWebView.canGoBack {
            wkWebView.goBack()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - WKURLSchemeHandler -
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        
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
