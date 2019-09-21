//
//  PlayViewController.swift
//  Numbers
//
//  Created by zlata samarskaya on 14.09.14.
//  Copyright (c) 2014 zlata samarskaya. All rights reserved.
//

import UIKit
import CoreGraphics
import AVFoundation
import GameKit
import QuartzCore

var MAX_LEVEL:Int = 9
var LEVEL_TIME:TimeInterval = 3 * 60

func getRandom(_ min: Int, max: Int) -> Int {
    return Int(min) + Int(arc4random_uniform(UInt32(max - min) + 1));
}

class PlayViewController: UIViewController {
    var gameView: UIView!
    @IBOutlet weak var gameOverView: UILabel!
    @IBOutlet weak var scoresLabel: UILabel!
    @IBOutlet weak var highScoresLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    var animationView: UIView!
    var leaderboardIdentifier:String = ""

    var maxPosition: Int = 5
    var colsCount: Int = 6
    var rowsCount: Int = 11
    var currentDigitView: DigitView!
    var digitsViews: NSMutableArray = NSMutableArray()
    var falledViews: NSMutableArray = NSMutableArray()
    var digitViewWidth: CGFloat!
    var scores: Int = 0
    var timer: Timer!
    var levelsTimer: Timer!
    var complexity: ComplexityEnum = ComplexityEnum.square
    let maxDigit: Int = 9
    var tickTime: TimeInterval = 0.7
    var levelTickStarted: TimeInterval = 0
    var levelTickPaused: TimeInterval = 0
    var level: Int = 1
    var audioPlayer: AVAudioPlayer?
    var bannerHeight: Int = 0
    var panelHeight: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameOverView.layer.masksToBounds = true
        gameOverView.layer.cornerRadius = 16
        gameOverView.layer.borderColor = UIColor.black.cgColor
        gameOverView.backgroundColor = UIColor(red: 0.2156, green: 0.13725, blue: 0.44706, alpha: 0.7)
        self.gameOverView.alpha = 0;
        
        levelLabel.text = NSString(format:"%@: %d", localized("Level"), level) as String
        scoresLabel.text = NSString(format:"%@: %d", localized("Scores"), scores) as String
        self.highScoresLabel.text = NSString(format: "%@: %d", localized("High Score"), 0) as String

        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: .default)
            } else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.soloAmbient)
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        if let background = self.view.viewWithTag(111) as? UIImageView {
            let h = UIScreen.main.bounds.height
            if(h < CGFloat(500.0)) {
                background.image = UIImage(named:"fon_phone4")
            } else {
                var height = UIScreen.main.bounds.height
                if #available(iOS 11.0, *) {
                    if let window = UIApplication.shared.keyWindow {
                        height -= window.safeAreaInsets.bottom
                    }
                }
                let image = UIImage(named:"fon_phone5")!
                background.image = image.imageAspectScaled(toFillWidth: UIScreen.main.bounds.width)
            }
        }
        if let highScores = UserDefaults.standard.value(forKey: self.complexity.liderBoard()) as? String {
            self.highScoresLabel.text = NSString(format: "%@: %@", localized("High Score"), highScores) as String
        }  else {
            UserDefaults.standard.setValue("", forKey: self.complexity.liderBoard())
        }
        self.loadLiderboard()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        colsCount = 6;
        rowsCount = 9;
        var frame = self.view.frame;
        var offset: CGFloat = 0
      if(UIDevice.current.userInterfaceIdiom == .pad) {
            panelHeight = 68
            bannerHeight = 90
            let scaleFactor = UIScreen.main.bounds.width / 768
            frame.origin.x = (108 * scaleFactor)
            digitViewWidth = (UIScreen.main.bounds.width - frame.origin.x * 2) / CGFloat(colsCount)
            offset = 1
        } else {
            panelHeight = 60
            bannerHeight = 50
            let scaleFactor = UIScreen.main.bounds.width / 320
            frame.origin.x = (4 * scaleFactor)
            digitViewWidth = (UIScreen.main.bounds.width - frame.origin.x * 2) / CGFloat(colsCount)
            offset = 0
            let h = self.view.frame.size.height
            if(h < CGFloat(500.0)) {
                digitViewWidth = 43.5//4s
                frame.origin.x = 29
            }
        }
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if !delegate.freeVersion {
            bannerHeight = 0;
        } else {
            //self.addBanner()
        }
        if #available(iOS 11.0, *) {
            if let window = UIApplication.shared.keyWindow {
                offset = window.safeAreaInsets.bottom
            }
        }
 
        maxPosition = colsCount - 1
     
        frame.size.width = CGFloat(colsCount) * digitViewWidth
        frame.size.height = CGFloat(rowsCount) * digitViewWidth
        frame.origin.y = self.view.frame.size.height - frame.size.height - CGFloat(offset)
        
        gameView = UIView(frame: frame)
        self.view.insertSubview(gameView, belowSubview:gameOverView)
        animationView = UIView(frame: gameView.bounds)
        gameView.addSubview(animationView)

        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)));
        
        self.startGame();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
       
        self.stopGame();
    }
   
    //  MARK - GC
    func loadLiderboard() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if delegate.gameCenterEnabled {
            let leaderboardRequest = GKLeaderboard()
            leaderboardRequest.playerScope = .global;
            leaderboardRequest.timeScope = .allTime;
            //leaderboardRequest.category = "HighScore";
            leaderboardRequest.range = NSMakeRange(1, 5);
            leaderboardRequest.identifier = self.complexity.liderBoard()
            leaderboardRequest.loadScores(completionHandler: { ( scArray:[AnyObject]!, error: Error!) -> Void in
                if error != nil {
                    print(error);
                } else {
                    if let localPlayerScore = leaderboardRequest.localPlayerScore {
                        self.highScoresLabel.text = NSString(format: "%@: %ld", localized("High Score"), localPlayerScore.value) as String
                        UserDefaults.standard.setValue(self.highScoresLabel.text,
                            forKey: self.complexity.liderBoard())
                    }
                }
            })
        }
    }

    func reportScore (userScore: Int) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if delegate.gameCenterEnabled {
            let score = GKScore(leaderboardIdentifier: self.complexity.liderBoard())
            score.value = Int64(userScore)
            
            GKScore.report([score], withCompletionHandler: { ( error: Error!) -> Void in
                
                })
        }
        if let highScores = UserDefaults.standard.value(forKey: self.complexity.liderBoard()) as? String {
            if  (userScore > (Int(highScores) ?? 0)) {
                let scoresStr = NSString(format:"%ld", userScore)
                UserDefaults.standard.setValue(scoresStr, forKey: self.complexity.liderBoard())
            }
        }
        
    }
    
    //  MARK - start - stop
    @IBAction func pause() {
        pauseButton.isSelected = !pauseButton.isSelected;
        if pauseButton.isSelected {
            timer.invalidate()
            levelsTimer.invalidate()
            levelTickPaused = NSDate().timeIntervalSince1970
        } else {
            let tickT: TimeInterval = tickTime - TimeInterval(Float(level - 1) * 0.05)
            timer = Timer.scheduledTimer(timeInterval: tickT, target: self,
                                         selector: #selector(tick), userInfo: nil, repeats: true);
            if level < MAX_LEVEL {
                let elapsed = levelTickStarted - levelTickPaused
                levelsTimer = Timer.scheduledTimer(timeInterval: (LEVEL_TIME + elapsed),
                                                   target: self,
                                                   selector: #selector(levelTick),
                                                   userInfo: nil,
                                                   repeats: false);
            }
        }
    }
    
    func stopGame () {
        timer.invalidate()
        levelsTimer.invalidate()
    }
    
    func startGame() {
        scores = 0
        digitsViews = NSMutableArray()
        for _ in 0...rowsCount {
            let viewsArray: NSMutableArray = NSMutableArray();
            for _ in 0...colsCount {
                viewsArray.add(NSNull());
            }
            digitsViews.add(viewsArray);
        }

        timer = Timer.scheduledTimer(timeInterval: tickTime, target: self, selector: #selector(tick), userInfo: nil, repeats: true);
        levelsTimer = Timer.scheduledTimer(timeInterval: LEVEL_TIME, target: self, selector: #selector(levelTick), userInfo: nil, repeats: false);
        levelTickStarted = NSDate().timeIntervalSince1970
        audioPlayer = AVAudioPlayer()
    }
    
    func gameOver () {
        self.reportScore(userScore: scores)
        let scoresStr = NSString(format:"%ld", Int(scores))
        gameOverView.text = NSString(format:"%@ %@", localized("Game Over!\nYour scores"), scoresStr) as String;
        UIView.animate(withDuration: 0.5, animations: {
            self.gameOverView.alpha = 1;
            }, completion: {(finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    self.dismiss(animated: true, completion: nil);
                })
        });
    }
    
    @objc func levelTick () {
        let tickT: TimeInterval = tickTime - TimeInterval(Float(level) * 0.05)
        level += 1
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: tickT, target: self, selector: #selector(tick), userInfo: nil, repeats: true);
        
        levelLabel.text = NSString(format:"%@: %d", localized("Level"), level) as String;
        if level < MAX_LEVEL {
            levelTickStarted = NSDate().timeIntervalSince1970
            levelsTimer = Timer.scheduledTimer(timeInterval: LEVEL_TIME, target: self, selector: #selector(levelTick), userInfo: nil, repeats: false);
        } else {
            levelsTimer.invalidate()
        }
    }

    //MARK - add digits
    func addNextDigit() {
        if !self.hasValidPosition() {
            self.gameOver(); return;
        }
        var pos: Int = getRandom(0, max: Int(maxPosition));
        while self.invalidPosition(pos) {
            pos += 1
            if pos > maxPosition {pos = 0;}
            //pos = self.getRandom(0, max: maxPosition);
        };
        
        let xPos = CGFloat(pos) * digitViewWidth
        let yPos = rowsCount + 1
        let rect = CGRect(x: CGFloat(xPos), y: -digitViewWidth,
            width: digitViewWidth, height: digitViewWidth);
       
        var nextDigit: Int = getRandom(1, max: maxDigit);
        repeat {
            nextDigit = getRandom(1, max: maxDigit)
        } while (self.isRoundNumber(nextDigit))
        
        let digitView: DigitView = self.getViewForDigit(frame: rect, digit: nextDigit);
        //digitView.backgroundColor = UIColor.darkGrayColor();
        digitView.pos.y = yPos
        digitView.pos.x = pos
        
        self.currentDigitView = digitView;
       // digitsViews.add(currentDigitView);
        self.gameView.addSubview(digitView);
    }
    
    func getViewForDigit(frame: CGRect, digit: Int) -> DigitView {
        let digitView: DigitView = DigitView(frame: frame, digit: digit);
        
        return digitView;
    }
    
    func playSound(path: NSString) {
       // runAction(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
        if let alertSound = Bundle.main.url(forResource: path as String, withExtension: "mp3") {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: alertSound, fileTypeHint: AVFileType.mp3.rawValue)
                audioPlayer?.play()
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }

    //  MARK - playing
    @objc func tick() {
        if (currentDigitView == nil) {
            if  falledViews.count > 0 {
                for view in falledViews {
                    let dView = view as! DigitView
                    let removes = self.checkRound(falledView: dView)
                    if  (removes.count > 0) {
                        break
                    }
                }
            }
            self.addNextDigit();
            return;
        }

        var rect : CGRect = self.currentDigitView.frame;
        //рассчитываем след позицию
       // var fieldHeight = CGFloat(digitViewWidth * rowsCount);
        rect.origin.y += rect.size.height;
        if (rect.origin.y + rect.size.height >= gameView.frame.size.height) {
            rect.origin.y = gameView.frame.size.height - rect.size.height;
        }
        //вычисляем след позицию в массиве
        let yPos:Int = Int(round((gameView.frame.size.height - (rect.origin.y + 5.0)) / digitViewWidth)) - 1
        let xPos:Int = self.currentDigitView.pos.x
        
        //println("NEW TICK \(xPos) \(yPos)");
        var row: NSMutableArray = self.digitsViews[yPos] as! NSMutableArray;
        //получаем объект след позиции
        if let digitView  = row[xPos] as? DigitView {
            //если след позиция уже занята, останавливаем объект на текущей позиции, проверяем если ли объекты для удаления
            if digitView.digit > 0  {
                //println("DV \(digitView.digit) posY \(yPos) rectY \(rect.origin.y)")
                row = self.digitsViews[yPos + 1] as! NSMutableArray;
                self.currentDigitView.pos.x = Int(xPos);
                self.currentDigitView.pos.y = Int(yPos) + 1;
                row[xPos] = currentDigitView;
                
                let _ = self.checkRound(falledView: self.currentDigitView)
                currentDigitView = nil;
                return;
            }
        }
        self.playSound(path: "down")
        self.currentDigitView.pos.y = yPos;
  
        UIView.animate(withDuration: 0.3, animations: {
                self.currentDigitView.frame = rect;
            }, completion: { (finished: Bool) in
                if self.currentDigitView == nil {return}
                //достигли "пола"
                if (yPos == 0) {
                    row = self.digitsViews[0] as! NSMutableArray;
                    self.currentDigitView.pos.x = Int(xPos);
                    self.currentDigitView.pos.y = 0;
                    row[xPos] = self.currentDigitView;

                    let _ = self.checkRound(falledView: self.currentDigitView);
                    self.currentDigitView = nil;
                    //println("VIEW REMOVED");
                    return;
                }
            });
    }

    //  MARK - check results
    func hasValidPosition() -> Bool {
        var count = 0
        let row: NSMutableArray = self.digitsViews[rowsCount - 1] as! NSMutableArray;
        for i in 0...colsCount - 1 {
            if let _ = row[i] as? DigitView {
                count += 1
            }
        }
        return count < colsCount;
    }
    
    func invalidPosition(_ pos: Int) -> Bool {
        let row: NSMutableArray = self.digitsViews[rowsCount - 1] as! NSMutableArray;
            if let _ = row[pos] as? DigitView {
                return true;
            }
        return false;
    }
    
    func checkRound(falledView: DigitView?) -> NSArray {
        
        if let fView = falledView {
            var removes: NSArray?

            switch self.complexity {
            case ComplexityEnum.line:
                removes = self.checkLine(fView)
            case ComplexityEnum.square:
                removes = self.checkSmallSquare(fView)
            case ComplexityEnum.bigSquare:
                removes = self.checkBigSquare(fView)
            case ComplexityEnum.twoDigits:
                removes = self.checkLine(2, falledView: fView)
            case ComplexityEnum.threeDigits:
                removes = self.checkLine(3, falledView: fView)
            case ComplexityEnum.forDigits:
                removes = self.checkLine(4, falledView: fView)
            case ComplexityEnum.rectangle:
                removes = self.checkRectangle(fView)
            }
            
            if let viewForRemoves = removes {
                self.falledViews = self.removeViews(views: viewForRemoves);
                return viewForRemoves
            }
        }
        return NSArray()
    }
    
    //  MARK - compute results
    func removeViews(views : NSArray) -> NSMutableArray {
        self.playSound(path: "fire")
        let allAboveViews:NSMutableArray = NSMutableArray()
        for view in views {
            let dView = view as! DigitView
            scores += dView.digit
            let aboveViews:NSMutableArray = NSMutableArray()
            var y :Int = Int(dView.pos.y) + 1;
            //for ; y < rowsCount ; y += 1 {
            while y < rowsCount {
                let row:NSMutableArray = self.digitsViews[y] as! NSMutableArray;
                let aView: AnyObject = row[Int(dView.pos.x)] as AnyObject;
                if let aboveView:DigitView = aView as? DigitView {
                        aboveViews.add(aboveView)
                }
                y += 1
            }
            allAboveViews.addObjects(from: aboveViews as [AnyObject])
            UIView.animate(withDuration: 0.3, animations: {
                for (index, _) in aboveViews.enumerated()   {
                    let view: DigitView = aboveViews[index] as! DigitView;
                    var rect: CGRect = view.frame;
                    rect.origin.y += rect.size.height;
                    view.frame = rect;
                    view.pos.y -= 1;
                    (self.digitsViews[Int(view.pos.y)] as! NSMutableArray).replaceObject(at: Int(view.pos.x), with: view);
                    (self.digitsViews[Int(view.pos.y + 1)] as! NSMutableArray).replaceObject(at: Int(view.pos.x), with: NSNull());
                }
                   // dView.transform = CGAffineTransformMakeScale(0.2, 0.2);
                }, completion: {(finished: Bool) in
                    //dView.removeFromSuperview();
                    if aboveViews.count == 0 {
                        (self.digitsViews[Int(dView.pos.y)] as! NSMutableArray).replaceObject(at: Int(dView.pos.x), with: NSNull());
                    }
           });
        }
        self.animateRemovingViews(views: views);
        scoresLabel.text = NSString(format:"%@: %d", localized("Scores"), scores) as String;
        return allAboveViews;
    }
    
    func animateRemovingViews(views: NSArray) {
        var topLeft = CGPoint(x: self.view.frame.size.width, y: self.view.frame.size.height), bottomRight = CGPoint()
        for view in views {
            let dView = view as! DigitView;
            if topLeft.y > dView.frame.origin.y && topLeft.x > dView.frame.origin.x {
                topLeft = dView.frame.origin
            }
            let bottomPos = CGPoint(x: dView.frame.origin.x + dView.frame.size.width, y: dView.frame.origin.y + dView.frame.size.height)
            if bottomRight.y < bottomPos.y && bottomRight.x < bottomPos.x { bottomRight = bottomPos }
        }
        self.animationView.frame = CGRect(origin: topLeft, size: CGSize(width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y))
        for view in views {
            let dView = view as! DigitView;
            var rect = dView.frame
            rect.origin.y -= topLeft.y
            rect.origin.x -= topLeft.x
            dView.frame = rect
            dView.removeFromSuperview()
            animationView.addSubview(dView)
        }
            UIView.animate(withDuration: 0.3, animations: {
                self.animationView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1);
                // self.animationView.center = self.currentDigitView.center
                }, completion: {(finished: Bool) in
                    for view in self.animationView.subviews {
                        view.removeFromSuperview()
                    }
                    self.animationView.transform = .identity
                    self.animationView.frame = self.gameView.bounds;
            });
   }
    //  MARK - Actions
    @IBAction func handleTap (sender: UITapGestureRecognizer) {
        if currentDigitView == nil {return}
        if pauseButton.isSelected {return}
        var point: CGPoint = sender.location(in: gameView);
        
        var rect : CGRect = self.currentDigitView.frame;
        if (point.y < rect.origin.y) {
            point.y = rect.origin.y
        }
        //for var i : Int = 0; i <= maxPosition; i += 1 {
        for i in 0...maxPosition {
            let xPos = CGFloat(i) * digitViewWidth;

            rect = CGRect(x: CGFloat(xPos), y: point.y - 10, width: CGFloat(digitViewWidth), height: CGFloat(digitViewWidth));
            if rect.contains(point) {break};
        }
        //for var i : Int = 0; ; i += 1 {
        var i = 0
        while true {
            let yPos = CGFloat(i) * digitViewWidth;
            if CGFloat(yPos) >= gameView.frame.size.height {break;}
            rect.origin.y = CGFloat(yPos);
            if rect.contains(point) {break};
            i += 1
        }
        
        let xPos:Int = Int(round(rect.origin.x / digitViewWidth))
        let yPos:Int = Int(round((gameView.frame.size.height - rect.origin.y) / digitViewWidth)) - 1

        let dv = self.digitsViews[yPos] as! NSMutableArray
        if dv[xPos] as? DigitView != nil {
            return;
        }
        
        if (rect.origin.y + rect.size.height >= self.gameView.frame.size.height) {
            rect.origin.y = self.gameView.frame.size.height - rect.size.height;
        }
        self.playSound(path: "tap")
        
        self.currentDigitView.frame = rect;
        self.currentDigitView.pos.x = xPos
        self.currentDigitView.pos.y = yPos
    }
    
    @IBAction func close () {
        self.stopGame()
        self.gameOver()
        //
    }
    
    //  MARK - Calculations
    func checkSmallSquare(_ falledView: DigitView) -> NSArray? {
        let left: Int = falledView.pos.x, right: Int = falledView.pos.x,
        top: Int = falledView.pos.y, bottom: Int = falledView.pos.y
        if left > 0 && bottom > 0 {
            let res = self.calculatedMatrixSum(left - 1, right: right, top: top, bottom: bottom - 1);
            let sum = res.sum
            if  res.matrix.count == 4 && self.isRoundNumber(sum) {
                
                return res.matrix
            }
        }
        if Int(right) < maxPosition && bottom > 0 {
            let res = self.calculatedMatrixSum(left, right: right + 1, top: top, bottom: bottom - 1);
            let sum = res.sum
            if  res.matrix.count == 4 && self.isRoundNumber(sum) {
                
                return res.matrix
            }
        }
        return nil;
    }
    
    func checkBigSquare(_ falledView: DigitView) -> NSArray? {
        let left: Int = falledView.pos.x, right: Int = falledView.pos.x,
        top: Int = falledView.pos.y, bottom: Int = falledView.pos.y
        if left > 0 && bottom - 1 > 0 && Int(right) < maxPosition {
            let res = self.calculatedMatrixSum(left - 1, right: right, top: top, bottom: bottom - 2);
            let sum = res.sum
            if  res.matrix.count == 9 && self.isRoundNumber(sum) {
                
                return res.matrix
            }
        }
        if left - 1 > 0 && bottom - 1 > 0 {
            let res = self.calculatedMatrixSum(left - 2, right: right, top: top, bottom: bottom - 2);
            let sum = res.sum
            if  res.matrix.count == 9 && self.isRoundNumber(sum) {
                
                return res.matrix
            }
        }
        if Int(right) + 1 < maxPosition && bottom - 1 > 0 {
            let res = self.calculatedMatrixSum(left, right: right + 2, top: top, bottom: bottom - 2);
            let sum = res.sum
            if  res.matrix.count == 9 && self.isRoundNumber(sum) {
                
                return res.matrix
            }
        }
        return nil;
    }

    func checkRectangle(_ falledView: DigitView) -> NSArray? {
        let left: Int = falledView.pos.x, right: Int = falledView.pos.x,
        top: Int = falledView.pos.y, bottom: Int = falledView.pos.y
        if bottom == 0 {return nil;}
        
        var sumViews = [NSArray]()
        var sums = [Int]()

        if left > 0 && bottom - 1 > 0 {
            let res = self.calculatedMatrixSum(left - 1, right: right, top: top, bottom: bottom - 2);
            let sum = res.sum
            if  res.matrix.count == 6 && self.isRoundNumber(sum) {
                sums.append(sum)
                sumViews.append(res.matrix)
            }
        }
        if Int(right) < maxPosition && bottom - 1 > 0 {
            let res = self.calculatedMatrixSum(left, right: right + 1, top: top, bottom: bottom - 2);
            let sum = res.sum
            if  res.matrix.count == 6 && self.isRoundNumber(sum) {
                sums.append(sum)
                sumViews.append(res.matrix)
            }
        }
        if Int(right) < maxPosition && left > 0 {
            let res = self.calculatedMatrixSum(left - 1, right: right + 1, top: top, bottom: bottom - 1);
            let sum = res.sum
            if  res.matrix.count == 6 && self.isRoundNumber(sum) {
                sums.append(sum)
                sumViews.append(res.matrix)
            }
        }
        if left - 1 > 0 {
            let res = self.calculatedMatrixSum(left - 2, right: right, top: top, bottom: bottom - 1);
            let sum = res.sum
            if  res.matrix.count == 6 && self.isRoundNumber(sum) {
                sums.append(sum)
                sumViews.append(res.matrix)
            }
        }
        if Int(right) + 1 < maxPosition && left > 0 {
            let res = self.calculatedMatrixSum(left, right: right + 2, top: top, bottom: bottom - 1);
            let sum = res.sum
            if  res.matrix.count == 6 && self.isRoundNumber(sum) {
                sums.append(sum)
                sumViews.append(res.matrix)
            }
        }
        if sums.count == 0 {
            return nil;
        }
        var maxSum:Int = 0, maxViews:NSArray?
        for index in 0...sums.count - 1 {
            if maxSum < sums[index] {
                maxSum = sums[index]
                maxViews = sumViews[index]
            }
        }
        return maxViews;
    }

    func checkLine(_ lenght: Int, falledView: DigitView) -> NSArray? {
        var left: Int = falledView.pos.x, right: Int = falledView.pos.x,
        top: Int = falledView.pos.y, bottom: Int = falledView.pos.y
        var horisontalLine: NSArray?
        var horisontalSum : Int = 0
        var verticalLine: NSArray?
        var verticalSum : Int = 0
        let posX = falledView.pos.x

        if posX > 0 {
           //for (var i = 1; i <= posX;  += 1i) {
            for i in 1...posX {
                if i >= lenght {
                    break;
                }
                let dv = self.digitsViews[falledView.pos.y] as! NSMutableArray
                if let view = dv[Int(posX - i)] as? DigitView {
                    left = view.pos.x
                }
            }
        }
        if Int(posX) < maxPosition {
            var i = 1
            var pos = Int(posX + i)
            //for var i: Int = 1; Int(posX + i) <= maxPosition; i += 1 {
            while (pos <= maxPosition) {
                if i >= lenght {
                    break;
                }
                let dv = self.digitsViews[falledView.pos.y] as! NSMutableArray
                if let view = dv[Int(posX + i)] as? DigitView {
                    right = view.pos.x
                }
                i += 1
                pos = Int(posX + i)
            }
        }
        if right - left >= lenght - 1 {
           // for var i = left; i <= falledView.pos.x; i += 1 {
            for i in left..<falledView.pos.x + 1 {
                //for var j = right; j >= falledView.pos.x; j-- {
                var j = right
                while (j >= falledView.pos.x) {
                    if i == j || j - i != lenght - 1 {
                        j -= 1
                        continue
                    }
                    let res = self.calculatedMatrixSum(i, right: j, top: top, bottom: bottom);
                    if  self.isRoundNumber(res.sum) {
                        if  (res.sum > horisontalSum){
                            horisontalLine = res.matrix
                            horisontalSum = res.sum
                        }
                    }
                    j -= 1
                }
            }
        }
        if top >= lenght  - 1 {
            bottom = top - lenght + 1;
            right = falledView.pos.x;
            left = falledView.pos.x;
            var res = self.calculatedMatrixSum(left, right: right, top: top, bottom: bottom);
            if  self.isRoundNumber(res.sum) {
                verticalSum = res.sum
                verticalLine = res.matrix
            }
        }
        if verticalSum > 0 && verticalSum > horisontalSum {return verticalLine}
        if horisontalSum > 0 && horisontalSum >= verticalSum {return horisontalLine}
        
        return nil;
    }
    
    func checkLine(_ falledView: DigitView) -> NSArray? {
        var left: Int = falledView.pos.x, right: Int = falledView.pos.x,
        top: Int = falledView.pos.y, bottom: Int = falledView.pos.y
        if left > 0 {
            //for var i = 1; i <= Int(falledView.pos.x); i += 1 {
            for i in 1...Int(falledView.pos.x) {
                let dv = self.digitsViews[falledView.pos.y] as! NSMutableArray
                if let view = dv[falledView.pos.x - i] as? DigitView {
                    left = view.pos.x
               }
            }
        }
        if Int(falledView.pos.x) < maxPosition {
            var pos = Int(falledView.pos.x)
            var i = 1
            //for var i = 1; Int(falledView.pos.x + i) <= maxPosition; i += 1 {
            while (pos <= maxPosition) {
                let dv = self.digitsViews[falledView.pos.y] as! NSMutableArray
                if let view = dv[falledView.pos.x + i] as? DigitView {
                    right = view.pos.x
                }
                i += 1
                pos += i
            }
        }
        var horisontalLine: NSArray?
        var horisontalSum : Int = 0
        if right - left >= 1 {
            //for var i = left; i <= falledView.pos.x; i += 1 {
            for i in left...falledView.pos.x {
                //for var j = right; j >= falledView.pos.x; j-- {
                var j = right
                while j >= falledView.pos.x {
                    if i == j {
                        j -= 1
                        continue
                    }
                    let res = self.calculatedMatrixSum(i, right: j, top: top, bottom: bottom);
                    if  self.isRoundNumber(res.sum) {
                        if  (res.sum > horisontalSum){
                            horisontalLine = res.matrix
                            horisontalSum = res.sum
                        }
                    }
                    j -= 1
                }
            }
        }

        if horisontalSum > 0 {return horisontalLine}
        
        return nil;
   }
    
    func isRoundNumber(_ number: Int) -> Bool {
        if number == 0 { return false }
        
        let v: Float = Float(number % 10)
        return v == 0
    }
    
    func calculateSum(left: Int, right: Int, top: Int, bottom: Int) -> Int {
        var sum: Int = 0//currentDigitView.digit;
        for row in bottom...top {
            for column in left...right {
                let dv = self.digitsViews[Int(row)] as! NSMutableArray
                if let view = dv[Int(column)] as? DigitView {
                    sum += view.digit;
                }
            }
        }
        return sum;
    }
    
    func calculatedMatrixSum(_ left: Int, right: Int, top: Int, bottom: Int) -> (matrix: NSArray, sum: Int) {
        let matrix:NSMutableArray = NSMutableArray();
        var sum: Int = 0//currentDigitView.digit;
        for row in bottom...top {
            for column in left...right {
                let dv = self.digitsViews[Int(row)] as! NSMutableArray
                if let view = dv[Int(column)] as? DigitView {
                    sum += view.digit;
                    matrix.add(view);
                } else {
                    return (NSMutableArray(), 0)
                }
            }
        }
        return (matrix, sum);
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    

}
