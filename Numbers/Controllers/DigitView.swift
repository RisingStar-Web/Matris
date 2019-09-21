//
//  DigitView.swift
//  Numbers
//
//  Created by zlata samarskaya on 14.09.14.
//  Copyright (c) 2014 zlata samarskaya. All rights reserved.
//

import UIKit

struct Position {
    var x: Int
    var y: Int
    init (xPos: Int, yPos: Int ) {
        x = xPos
        y = yPos
    }
    init () {
        x = 0
        y = 0
    }
}

class DigitView: UIView {
    var digit: Int = 0
    var pos: Position = Position(xPos: 0, yPos: 0)

    convenience init (frame: CGRect, digit: Int) {
        self.init(frame: frame);
        self.digit = digit;
 
        let index = getRandom(1, max: 4)
        let image = UIImage(named: String(format:"%dk.png", index))
        let imageView = UIImageView(image: image)
        imageView.frame.origin = CGPoint(x: 1,y: 1)
        imageView.frame.size = CGSize(width: frame.width - 2, height: frame.height - 2)
        self.addSubview(imageView)

        let label: UILabel = UILabel(frame: self.bounds)
        label.textColor = .white
        label.textAlignment = .center
        label.text = NSString(format: "%d", digit) as String
        let fontSize = UIDevice.current.userInterfaceIdiom == .pad ? 34.0 : 20.0
        label.font = UIFont.boldSystemFont(ofSize: CGFloat(fontSize))
        self.addSubview(label);
        
        self.backgroundColor = .clear
     }
}
