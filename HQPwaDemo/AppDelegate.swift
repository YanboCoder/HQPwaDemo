//
//  AppDelegate.swift
//  HQPwaDemo
//
//  Created by wang on 2021/1/28.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = UINavigationController(rootViewController: ViewController())
        self.window!.makeKeyAndVisible()
        
        return true
    }
}

