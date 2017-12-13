//
//  ViewController.swift
//  ContextualMenu
//
//  Created by Hector Matos on 12/12/17.
//  Copyright © 2017 Hector Matos. All rights reserved.
//

import UIKit
import iOSContextualMenu

// twitch.tv/krakendev
// Thanks for the sub on Twitch, aligt83! YOU ARE THE BEE'S KNEES
class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectionLabel: UILabel!
    @IBOutlet var optionButtons: [OptionsButton] = []
    
    var currentlyShownOptionButtons: [OptionsButton] {
        return optionButtons.filter { $0.isSelected }
    }
    
    let contextualMenu = ContextualMenu(menuType: .fan)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 1.0
        imageView.layer.cornerRadius = 4.0

        contextualMenu.delegate = self
        contextualMenu.dataSource = self
        imageView.addSubview(contextualMenu)
    }
}

// MARK: Event Handlers
extension ViewController {
    @IBAction func valueChangedForAnimateOutwardsSwitch(animateSwitch: UISwitch) {
        contextualMenu.shouldHighlightOutwards = animateSwitch.isOn
    }
    
    @IBAction func valueChangedForSegmentedControl(segmentedControl: UISegmentedControl) {
        guard let activateOption = ActivateOption(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        contextualMenu.activateOption = activateOption
    }
    
    @IBAction func optionsButtonTapped(button: OptionsButton) {
        button.isSelected = !button.isSelected
        contextualMenu.reloadData()
    }
}

// MARK: ContextualMenuDataSource
extension ViewController: ContextualMenuDataSource {
    func numberOfMenuItems(for menu: ContextualMenu) -> Int {
        return currentlyShownOptionButtons.count
    }
}

// MARK: ContextualMenuDelegate
extension ViewController: ContextualMenuDelegate {
    func contextualMenu(_ menu: ContextualMenu, viewForMenuItemAt index: Int) -> UIView {
        let imageView = UIImageView(image: currentlyShownOptionButtons[index].image)
        imageView.backgroundColor = .white
        return imageView
    }
    
    func contextualMenu(_ menu: ContextualMenu, titleForMenuItemAt index: Int) -> String {
        return currentlyShownOptionButtons[index].title
    }
}
