//
//  MasterViewController.swift
//  homelights
//
//  Created by Robert Diamond on 3/31/19.
//  Copyright © 2019 Robert Diamond. All rights reserved.
//

import UIKit

let ColorNotification = NSNotification.Name(rawValue: "ColorChanged")

class MasterViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, MQTTHandlerDelegate {
    func didConnect() {
        self.collectionView.allowsSelection = true
        self.spinner.stopAnimating()
    }

    func didDisconnect() {
        self.collectionView.allowsSelection = false
        self.spinner.startAnimating()
    }


    var detailViewController: DetailViewController? = nil
    var objects = [String]()
    let mqtt = MQTTHandler()
    let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.collectionView.allowsSelection = false
        self.collectionView.addSubview(spinner)
        spinner.center = self.collectionView.center
        spinner.startAnimating()
        mqtt.delegate = self
        navigationItem.leftBarButtonItem = editButtonItem

        setTitleAndRooms()
        NotificationCenter.default.addObserver(self, selector: #selector(self.colorChanged), name: ColorNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setTitleAndRooms), name: UserDefaults.didChangeNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    @objc
    func insertNewObject(_ label: String) {
        if !objects.contains(label) {
            self.mqtt.addRoom(room: label)
            objects.insert(label, at: 0)
            //let indexPath = IndexPath(item: 0, section: 0)
            //collectionView.insertItems(at: [indexPath])
        }
    }

    @objc
    func colorChanged(notification : Notification) {
        DispatchQueue.main.async(execute: {
            self.collectionView.reloadData()
        })
    }

    @objc
    func setTitleAndRooms() {
        if let title = UserDefaults.standard.string(forKey: "baseMqttClient") {
            self.title = title
        }
        if let rooms = UserDefaults.standard.array(forKey: "rooms") {
            for roomV in rooms {
                if let room = roomV as? String {
                    insertNewObject(room)
                }
            }
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPaths = collectionView.indexPathsForSelectedItems {
                print("indexpaths \(indexPaths)")
                let indexPath = indexPaths[0]
                let object = objects[indexPath.item]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.mqtt = mqtt
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Collection View

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return objects.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

        (cell.viewWithTag(2) as? UILabel)?.text = objects[indexPath.row]
        if let lightColor = self.mqtt.getColor(room: objects[indexPath.row]) {
            cell.contentView.viewWithTag(1)!.backgroundColor = lightColor
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let object = objects[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        let label = cell.viewWithTag(2) as? UILabel
        let font = label?.font
        let itemsz = object.boundingRect(with: CGSize(width: self.view.frame.width - 60, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font!], context: nil)
        return CGSize(width: itemsz.width + 20, height: itemsz.height + 40)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

