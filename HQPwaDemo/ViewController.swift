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
        
        let buttonArray = ["WKWebView", "SWWebView", "preload Service Worker", "Simple PWA", "clear cache of WKWebView"]
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
            wkVC.urlString = "https://yanboCoder.github.io/pwa-demos/minipwa/public/"
            self.navigationController?.pushViewController(wkVC, animated: true)
        case 2:
            self.loadServiceWorker()
        case 3:
            let simpleVC = YBWebViewController()
            self.navigationController?.pushViewController(simpleVC, animated: true)
        case 4:
            self.clearWKWebViewCache()
        default:
            print("error: this button have not action！")
        }
        
    }
    
    func loadServiceWorker() {
        var coordinator : SWWebViewCoordinator?
        var swView: SWWebView!
        let storageURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("testapp-db", isDirectory: true)

        do {
            if !FileManager.default.fileExists(atPath: storageURL.path) {
//                try FileManager.default.removeItem(at: storageURL)
                try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true, attributes: nil)
            }
            
        } catch {
            fatalError()
        }
        coordinator = SWWebViewCoordinator(storageURL: storageURL)
        swView = SWWebView(frame: CGRect.zero, configuration: WKWebViewConfiguration())
        swView.containerDelegate = coordinator
        let urlString = "https://yanboCoder.github.io/pwa-demos/minipwa/public/"
        guard let urlComps = URLComponents(string: urlString), let host = urlComps.host else {
            fatalError("must provide a valid url")
        }

        let domain: String = {
            if let port = urlComps.port, port != 80 && port != 443 {
                return "\(host):\(port)"
            }
            return host
        }()
        swView.serviceWorkerPermittedDomains.append(domain)
        do {
            _ = try swView.containerDelegate?.container(swView, createContainerFor: urlComps.url!.absoluteURL)
        } catch {

        }
        let swId = UUID().uuidString
        guard let url = URL(string: urlString) else {
            return
        }
        let serviceWorker = ServiceWorker.init(id: swId, url: url, state: .activated)
        _ = serviceWorker.getExecutionEnvironment()
        print("===== preload Service Worker ======")

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

