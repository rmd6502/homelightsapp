//
//  MQTTHandler.swift
//  homelights
//
//  Created by Robert Diamond on 3/31/19.
//  Copyright © 2019 Robert Diamond. All rights reserved.
//

import UIKit
import CocoaMQTT

struct Color : Codable {
    var color : String
    var brightness : Double
}

protocol MQTTHandlerDelegate {
    func didConnect()
    func didDisconnect()
}
class MQTTHandler: NSObject {
    var mqtt : CocoaMQTT5?
    var colors = [String:UIColor]()
    var re : NSRegularExpression!
    var rooms = [String]()
    let roomQ = DispatchQueue(label: "roomHandler")
    var disconnecting = false
    var host : String?

    var delegate : MQTTHandlerDelegate? {
        didSet {
            if mqtt?.connState == CocoaMQTTConnState.connected {
                delegate?.didConnect()
            }
        }
    }

    override init() {
        do {
            self.re = try NSRegularExpression(pattern: "/([^/]+)/color", options: [])
        } catch {}
        super.init()
        connectMqtt()
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: OperationQueue(),
            using: { notification in
                if let host = UserDefaults.standard.string(forKey: "mqttHost") {
                    if host != self.host { self.reconnect() }
                } else {
                    self.reconnect()
                }
            }
        )
    }
    
    @objc func reconnect() {
        DispatchQueue.main.async {
            self.delegate?.didDisconnect()
        }
        self.mqtt?.disconnect()
        connectMqtt()
    }

    func connectMqtt() {
        if let host = UserDefaults.standard.string(forKey: "mqttHost") {
            self.host = host
            if self.mqtt != nil && self.mqtt?.host == host && self.mqtt?.connState != CocoaMQTTConnState.disconnected {
                return
            }
            
            if (self.mqtt == nil) {
                self.mqtt = CocoaMQTT5(clientID:(UserDefaults.standard.string(forKey: "baseMqttClient") ?? "777") + UUID().uuidString, host: host)
                
                self.mqtt?.didConnectAck = {
                    mqtt, reasonCode, connectAck in
                    print("Connected")
                    self.roomQ.async(execute: {
                        for room in self.rooms {
                            mqtt.subscribe("/\(room)/color")
                        }
                    })
                    DispatchQueue.main.async {
                        self.delegate?.didConnect()
                    }
                }
                self.mqtt?.didSubscribeTopics = {
                    (mqtt, dict, success, failures) -> Void in
                    print("Subscribed to \(success)")
                }
                
                self.mqtt?.didReceiveMessage = {
                    mqtt, message, qos, suback in
                    print("message \(message.topic)")
                    do {
                        let result = self.re.matches(in: message.topic, range: NSRange(location: 0, length: message.topic.count))
                        if result.count > 0 {
                            let sr = result[0].range(at: 1)
                            let room = NSString(string: message.topic).substring(with: sr)
                            print("room \(room)")
                            let decoder = JSONDecoder()
                            decoder.nonConformingFloatDecodingStrategy = JSONDecoder.NonConformingFloatDecodingStrategy.convertFromString(positiveInfinity: "Inf", negativeInfinity: "-Inf", nan: "NaN")
                            let response = try decoder.decode(Color.self, from: Data(message.payload))
                            print("message data \(response)")
                            var colorVal : UInt32 = 0
                            print("color Val \(response.color.dropFirst(1))")
                            Scanner(string: String(response.color.dropFirst(1))).scanHexInt32(&colorVal)
                            print("colorVal \(colorVal)")
                            var r,g,b : CGFloat
                            r = CGFloat(colorVal >> 16) / 255.0
                            g = CGFloat(colorVal >> 8 & 255) / 255.0
                            b = CGFloat(colorVal & 255) / 255.0
                            let fullColor = UIColor(red: r, green: g, blue: b, alpha: 1)
                            var hue: CGFloat = 0, saturation: CGFloat = 0, bright: CGFloat = 0, alpha : CGFloat = 0
                            fullColor.getHue(&hue, saturation: &saturation, brightness: &bright, alpha: &alpha)
                            let resultColor = UIColor(hue: hue, saturation: saturation, brightness: CGFloat(response.brightness), alpha: 1)
                            NotificationCenter.default.post(name: ColorNotification, object: nil)
                            self.colors[room] = resultColor
                        }
                    } catch {
                        print(error)
                        print("\(String(describing: message.string))")
                    }
                }
                
                self.mqtt?.didDisconnect = {
                    mqtt, error in
                    print("Disconnected \(String(describing: error))")
                    DispatchQueue.main.async {
                        self.delegate?.didDisconnect()
                    }
                    if !self.disconnecting {
                        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now().advanced(by: .seconds(10))) {
                            self.connectMqtt()
                        }
                    }
                }
            }
            if !(self.mqtt?.connect(timeout: 10.0) ?? false) {
                print("Failed to request connection")
            }
        }
    }

    deinit {
        self.disconnecting = true
    }

    func addRoom(room: String) {
        self.roomQ.async(execute: {
            if self.mqtt != nil && self.mqtt?.connState == CocoaMQTTConnState.connected {
                self.mqtt?.subscribe("/\(room)/color")
            } else {
                self.rooms.append(room)
            }
        })
    }

    func removeRoom(room: String) {
        self.roomQ.async(execute: {
            if self.mqtt != nil && self.mqtt?.connState == CocoaMQTTConnState.connected {
                self.mqtt?.unsubscribe("/\(room)/color")
            } else {
                if let roomIdx = self.rooms.firstIndex(of: room) {
                    self.rooms.remove(at: roomIdx)
                }
            }
        })
    }

    func setColor(color: UIColor, room: String) {
        var hue: CGFloat = 0, saturation: CGFloat = 0, bright: CGFloat = 0, alpha : CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &bright, alpha: &alpha)
        let cf = UIColor(hue: hue, saturation: saturation, brightness: 1, alpha: 1)
        var r : CGFloat = 0,g : CGFloat = 0,b : CGFloat = 0
        cf.getRed(&r, green: &g, blue: &b, alpha: &alpha)
        let repr = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        let packet = Color(color: repr, brightness: Double(bright))
        var packetData : Data
        do { try packetData = JSONEncoder().encode(packet) }
        catch { return }
        if let stringPacket = String(bytes: packetData, encoding: String.Encoding.utf8) {
            mqtt?.publish("/\(room)/color", withString: stringPacket, qos: CocoaMQTTQoS.qos0, retained: true, properties: MqttPublishProperties())
        }
    }

    func getColor(room: String) -> UIColor? {
        return self.colors[room]
    }
}
