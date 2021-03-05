//
//  WKWebViewController.swift
//  HQPwaDemo
//
//  Created by wang on 2021/2/5.
//

import UIKit
import WebKit

class WKWebViewController: UIViewController {
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

        // Do any additional setup after loading the view.
        let webView: WKWebView = WKWebView.init(frame: self.view.frame)
        let  url = NSURL(string: "https://mdn.github.io/pwa-examples/js13kpwa/")
        let request = URLRequest(url: url! as URL)
        webView .load(request)
        self.view.addSubview(webView)
        
        self.wkWebView = webView
    }
}
