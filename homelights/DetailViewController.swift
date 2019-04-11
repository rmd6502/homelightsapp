//
//  DetailViewController.swift
//  homelights
//
//  Created by Robert Diamond on 3/31/19.
//  Copyright © 2019 Robert Diamond. All rights reserved.
//

import UIKit
import FlexColorPicker

class DetailViewController: UIViewController, ColorPickerDelegate {
    var mqtt : MQTTHandler?

    @IBOutlet weak var colorPickerControl: RadialPaletteControl!
    @IBOutlet weak var brightnessSlider: BrightnessSliderControl!

    var picker = ColorPickerController()

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            self.title = detail
            if let color = mqtt?.getColor(room: detail) {
                picker.selectedColor = color
                colorPickerControl.foregroundImageView.alpha = 1
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        picker.radialHsbPalette = colorPickerControl
        picker.brightnessSlider = brightnessSlider
        picker.delegate = self
        // Do any additional setup after loading the view.
        configureView()
    }

    var detailItem: String? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    func colorPicker(_ colorPicker: ColorPickerController, selectedColor: UIColor, usingControl: ColorControl) {
        print("selected color \(selectedColor) alpha \(colorPickerControl.foregroundImageView.alpha)")
        colorPickerControl.foregroundImageView.alpha = 1
        mqtt?.setColor(color: selectedColor, room: detailItem!)
    }

    func colorPicker(_ colorPicker: ColorPickerController, confirmedColor: UIColor, usingControl: ColorControl) {
        mqtt?.setColor(color: confirmedColor, room: detailItem!)
    }
}

