//
//  AppDelegate.swift
//  cropintegration
//
//  Created by Alex Khuala on 29.03.24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate 
{
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = KHTheme.color.back
        window.rootViewController = KHMainController(with: KHMainViewModel())
        window.makeKeyAndVisible()
        
        self.window = window
        
        
        return true
    }

}

