//
//  ModalViewController.swift
//  Numbers
//
//  Created by zlata samarskaya on 12.10.14.
//  Copyright (c) 2014 zlata samarskaya. All rights reserved.
//

import UIKit
import Foundation

class ModalViewController: UIViewController, UIWebViewDelegate {
    var mode:Int = 0
    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = Bundle.main.bundlePath;
        let baseUrl = NSURL.fileURL(withPath: path);
        let help = UIDevice.current.userInterfaceIdiom == .pad ? localized("help_Pad_") : localized("help_");
        webView.loadHTMLString(try! String(contentsOfFile: Bundle.main.path(forResource: help, ofType: "html")!, encoding: .utf8), baseURL: baseUrl)
        webView.delegate = self
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.scrollView.bounces = false
    }
    
    @IBAction func close() {
        self.dismiss(animated: true, completion: { () -> Void in
            
        })
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

}
