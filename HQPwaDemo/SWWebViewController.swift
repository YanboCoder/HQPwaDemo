//
//  SWWebViewController.swift
//  HQPwaDemo
//
//  Created by wang on 2021/2/22.
//

import GCDWebServer
import PromiseKit
import UIKit
import WebKit

class SWWebViewController: UIViewController {

    var coordinator: SWWebViewCoordinator?

    private var swView: SWWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.addStubs()
        let config = WKWebViewConfiguration()

        Log.info = { print("INFO: \($0)") }
        Log.debug = { print("DEBUG: \($0)") }
        Log.error = { print("ERROR: \($0)") }
        Log.warn = { print("WARN: \($0)") }

        let storageURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("testapp-db", isDirectory: true)

        do {
            if FileManager.default.fileExists(atPath: storageURL.path) == false {
//                try FileManager.default.removeItem(at: storageURL)
                try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true, attributes: nil)
            }
            
        } catch {
            fatalError()
        }

        self.coordinator = SWWebViewCoordinator(storageURL: storageURL)

        self.swView = SWWebView(frame: self.view.frame, configuration: config)
        // This will move to a delegate method eventually
        self.swView.containerDelegate = self.coordinator!
        self.view.addSubview(self.swView)

        title = "SWWebView"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))

        // MARK: - Home URL
        let urlString = "https://mdn.github.io/pwa-examples/js13kpwa/"

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
        URLCache.shared.removeAllCachedResponses()
        print("Loading \(urlComps.url!.absoluteString)")
        _ = self.swView.load(URLRequest(url: urlComps.url!))
    }
    
    @objc private func refresh() {
        swView.reload()
    }

    func addStubs() {
        SWWebViewBridge.routes["/ping"] = { _, _ in

            Promise.value([
                "pong": true
            ])
        }

        SWWebViewBridge.routes["/ping-with-body"] = { _, json in

            let responseText = json?["value"] as? String ?? "no body found"

            return Promise.value([
                "pong": responseText
            ])
        }
    }

}
