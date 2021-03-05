//
//  ViewController.swift
//  HQPwaDemo
//
//  Created by wang on 2021/1/28.
//

import UIKit
import WebKit
import PromiseKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .lightGray
        
        let buttonArray = ["WKWebView", "SWWebView", "preload Service Worker", "clear cache of WKWebView"]
        for (index, item) in buttonArray.enumerated() {
            let button = UIButton.init(type: .custom)
            button.frame = CGRect(x: 20, y: 200+index*100, width: Int(UIScreen.main.bounds.width - 40), height: 60)
            button.tag = index
            button.setTitle(item, for: UIControl.State.normal)
            button.backgroundColor = UIColor.red
            button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
            self.view.addSubview(button)
        }
    }
    
    @objc func buttonAction(sender: UIButton) {
        switch sender.tag {
        case 0:
            let wkVC = WKWebViewController()
            self.navigationController?.pushViewController(wkVC, animated: true)
        case 1:
            let wkVC = SWWebViewController()
            self.navigationController?.pushViewController(wkVC, animated: true)
        case 2:
            self.loadServiceWorker()
        case 3:
            self.clearWKWebViewCache()
        default:
            print("error: this button have not action！")
        }
        
    }
    
    func loadServiceWorker() {
//        let url = NSURL(string: "https://mdn.github.io/pwa-examples/js13kpwa/")
//        let registrationFactory: WorkerRegistrationFactory
    }
    
    func clearWKWebViewCache() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { (records) in
            for record in records{
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {
                    print("WKWebView 缓存清除成功\(record)")
                })
            }
        })
    }
}

