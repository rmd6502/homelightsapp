//
//  SettingsViewController.swift
//  homelights
//
//  Created by Robert Diamond on 4/7/19.
//  Copyright © 2019 Robert Diamond. All rights reserved.
//

import UIKit

class SettingsViewController : UIViewController {
    @IBOutlet weak var mqttHost: UITextField!
    @IBOutlet weak var baseClientName: UITextField!
    @IBOutlet weak var roomList: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let host = UserDefaults.standard.string(forKey: "mqttHost") {
            mqttHost.text = host
        }
        if let clientName = UserDefaults.standard.string(forKey: "baseMqttClient") {
            baseClientName.text = clientName
        }
        if let roomAnyArray = UserDefaults.standard.array(forKey: "rooms") {
            if let roomArray = roomAnyArray as? [String] {
                let rooms = roomArray.joined(separator: ",")
                roomList.text = rooms
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let host = mqttHost.text {
            let oldHost = UserDefaults.standard.string(forKey: "mqttHost")
            if oldHost == nil || oldHost != host {
                UserDefaults.standard.set(host, forKey: "mqttHost")
            }
        }
        if let clientName = baseClientName.text {
            let oldclientName = UserDefaults.standard.string(forKey: "mqttHost")
            if oldclientName == nil || oldclientName != clientName {
                UserDefaults.standard.set(clientName, forKey: "baseMqttClient")
            }
        }
        if let rooms = roomList.text {
            var roomArray = [String]()
            for room in rooms.split(separator: ",", maxSplits: Int.max, omittingEmptySubsequences: true) {
                roomArray.append(NSString(string: String(room)).trimmingCharacters(in: .whitespaces))
            }
            let oldRooms = UserDefaults.standard.array(forKey: "rooms") as? [String]
            if oldRooms == nil || oldRooms != roomArray {
                UserDefaults.standard.set(roomArray, forKey: "rooms")
            }
        }
    }
}
