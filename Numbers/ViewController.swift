//
//  ViewController.swift
//  Numbers
//
//  Created by zlata samarskaya on 14.09.14.
//  Copyright (c) 2014 zlata samarskaya. All rights reserved.
//

import UIKit
import GameKit

enum ComplexityEnum: UInt8 {
    case  twoDigits = 0, threeDigits, forDigits, line, square, rectangle, bigSquare
    func liderBoard() -> String {
        switch self {
        case .line:
            return "grp.digtris_line"
        case .twoDigits:
            return "grp.digtris_2d"
        case .threeDigits:
            return "grp.digtris_3d"
        case .forDigits:
            return "grp.digtris_4d"
        case .square:
            return "grp.square_2x2"
        case .rectangle:
            return "grp.square_3x3"
        case .bigSquare:
            return "grp.rectangle_2x3"
        }
    }
}

func localized(_ string: String) -> String {
    return NSLocalizedString(string, tableName: nil, bundle: Bundle.main, value: string, comment: string);
}

class ViewController: UITableViewController, GKGameCenterControllerDelegate {
    
    @IBOutlet weak var payButton: UIButton!
    var menuExpanded:Bool = false
    var menuItems:[String] = [localized("Start"), localized("Rules"), localized("Modes"), localized("High Scores"), localized("Other Apps")]
    var complexity:ComplexityEnum = ComplexityEnum(rawValue: 0)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.authenticateLocalPlayer()
        let imageName =  UIDevice.current.userInterfaceIdiom == .pad ? "back_pad.png" : "back_phone.png"

        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image)
//        imageView.alpha = 0.7
        self.tableView.backgroundView = imageView
        
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.navigationController?.isNavigationBarHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.authenticateLocalPlayer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell: UITableViewCell = sender as! UITableViewCell
        let path: IndexPath = tableView.indexPath(for: cell)!
        let controller: PlayViewController = segue.destination as! PlayViewController;
        controller.complexity = ComplexityEnum(rawValue: UInt8(path.row))!;
    }
    
    @IBAction func pay () {
        payButton.isSelected = !payButton.isSelected
            
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.freeVersion = payButton.isSelected
    }
    
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = {(viewController: UIViewController?, error: Error?) -> Void in
            let delegate = UIApplication.shared.delegate as! AppDelegate
           if viewController != nil {
                self.present(viewController!, animated: true, completion: nil)
            } else {
            if localPlayer.isAuthenticated {
                    delegate.gameCenterEnabled = true
                } else {
                    delegate.gameCenterEnabled = false
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (!self.menuExpanded || (self.menuExpanded && (indexPath.row < 3 || indexPath.row > 9))) {
            return UIDevice.current.userInterfaceIdiom == .pad ? 100 : 68
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (!self.menuExpanded || (self.menuExpanded && (indexPath.row < 3 || indexPath.row > 9))) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell")!
            if let button = cell.viewWithTag(111) as? UIButton {
                button.setTitle(menuItems[indexPath.row], for: .normal)
                button.removeTarget(nil, action: nil, for: .touchUpInside)
                
                switch indexPath.row {
                case 1:
                    button.addTarget(self, action: #selector(help), for: .touchUpInside)
                case 2:
                    button.addTarget(self, action: #selector(expand), for: .touchUpInside)
                case 0:
                    button.addTarget(self, action: #selector(startGame), for: .touchUpInside)
                case 3, 10:
                    button.addTarget(self, action: #selector(records), for: .touchUpInside)
                case 4, 11:
                    button.addTarget(self, action: #selector(otherApps), for: .touchUpInside)
                default:
                    break;
                }

               // button.tag = indexPath.row
            }
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.frame.size.width, bottom: 0, right: 0);
            cell.backgroundColor = .clear
            return cell
        }
        
        let cell:UITableViewCell = UITableViewCell(style: .default, reuseIdentifier: "textCell")
        cell.textLabel?.text = menuItems[indexPath.row]
        cell.textLabel?.textColor = .white
        let offset = UIDevice.current.userInterfaceIdiom == .pad ? 220 : 25
        cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat(offset), bottom: 0, right: CGFloat(offset))
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        if (indexPath.row == Int(self.complexity.rawValue) + 3) {
            cell.textLabel?.text = NSString(format: "✔︎ %@",menuItems[indexPath.row]) as String
            //cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.textLabel?.text = menuItems[indexPath.row]
            //cell.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (!self.menuExpanded || (self.menuExpanded && (indexPath.row < 3 || indexPath.row > 9))) {
            return
        }
            self.complexity = ComplexityEnum(rawValue: UInt8(indexPath.row - 3))!
            self.tableView.reloadData()
    }
    
    @IBAction func menuButtonTap (sender :UIButton) {
    
        switch sender.tag {
            case 1:
            self.help()
            case 2:
            self.expand()
            case 0:
            self.startGame()
            case 3, 9:
            self.records()
            case 4, 11:
            self.otherApps()
            default:
            break;
        }
    }
    
    @objc func expand() {
        self.menuExpanded = !self.menuExpanded
        if  (menuExpanded) {
            
            menuItems = [localized("Start"), localized("Rules"), localized("Modes"), localized("2 digits"), localized("3 digits"),
                localized("4 digits"), localized("Line"), "2х2" , "2х3", "3х3", localized("High Scores"), localized("Other Apps")]
        } else {
            menuItems = [localized("Start"), localized("Rules"), localized("Modes"), localized("High Scores"), localized("Other Apps")]
        }
        let indices: IndexSet = [0]
        self.tableView.reloadSections(indices, with: .automatic)
    }
    
    @objc func otherApps () {
        UIApplication.shared.openURL(URL(string: "https://itunes.apple.com/ru/artist/iplanetsoft/id483944805")!)
    }
    
    @objc func records () {
        let leaderboardViewController = GKGameCenterViewController()
        leaderboardViewController.gameCenterDelegate = self;
        self.present(leaderboardViewController, animated:true, completion: {})

    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: { () -> Void in
            
        })
    }
    
    @objc func help () {
        let sbName =  "Main_Phone"
        let storyBoard = UIStoryboard(name:sbName, bundle:nil)
        let controller: ModalViewController = storyBoard.instantiateViewController(withIdentifier: "ModalViewController") as! ModalViewController
        
        self.present(controller, animated: true, completion: {})
    }
    
    @objc func startGame() {
        let sbName =  UIDevice.current.userInterfaceIdiom == .pad ? "Main_Pad" : "Main_Phone"
        let storyBoard = UIStoryboard(name:sbName, bundle:nil)
        let controller: PlayViewController = storyBoard.instantiateViewController(withIdentifier: "PlayViewController") as! PlayViewController
        controller.complexity = complexity;
        self.present(controller, animated: true, completion: {})
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

class MNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}

