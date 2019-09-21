//
//  AppDelegate.swift
//  Numbers
//
//  Created by zlata samarskaya on 14.09.14.
//  Copyright (c) 2014 zlata samarskaya. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    var freeVersion: Bool = false
    var gameCenterEnabled:Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let sbName =  UIDevice.current.userInterfaceIdiom == .pad ? "Main_Pad" : "Main_Phone"
        let storyBoard = UIStoryboard(name:sbName, bundle:nil)
        if let initViewController: UIViewController = storyBoard.instantiateInitialViewController(),
            let window = self.window {
            window.rootViewController = initViewController
        }
        
        return true
    }

}

