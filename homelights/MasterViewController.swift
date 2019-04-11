//
//  MasterViewController.swift
//  homelights
//
//  Created by Robert Diamond on 3/31/19.
//  Copyright © 2019 Robert Diamond. All rights reserved.
//

import UIKit

let ColorNotification = NSNotification.Name(rawValue: "ColorChanged")

class MasterViewController: UITableViewController, MQTTHandlerDelegate {
    func didConnect() {
        self.tableView.allowsSelection = true
        self.spinner.stopAnimating()
    }

    func didDisconnect() {
        self.tableView.allowsSelection = false
        self.spinner.startAnimating()
    }


    var detailViewController: DetailViewController? = nil
    var objects = [String]()
    let mqtt = MQTTHandler()
    let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.tableView.allowsSelection = false
        self.tableView.addSubview(spinner)
        spinner.center = self.tableView.center
        spinner.startAnimating()
        mqtt.delegate = self
        navigationItem.leftBarButtonItem = editButtonItem

        NotificationCenter.default.addObserver(self, selector: #selector(self.colorChanged), name: ColorNotification, object: nil)

        if let rooms = UserDefaults.standard.array(forKey: "rooms") {
            for roomV in rooms {
                if let room = roomV as? String {
                    insertNewObject(room)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    @objc
    func insertNewObject(_ label: String) {
        self.mqtt.addRoom(room: label)
        objects.insert(label, at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    @objc
    func colorChanged(notification : Notification) {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.mqtt = mqtt
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel!.text = objects[indexPath.row]
        if let lightColor = self.mqtt.getColor(room: objects[indexPath.row]) {
            cell.contentView.viewWithTag(42)!.backgroundColor = lightColor
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

