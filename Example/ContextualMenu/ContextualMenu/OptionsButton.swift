//
//  OptionsButton.swift
//  ContextualMenu
//
//  Created by Hector Matos on 12/12/17.
//  Copyright © 2017 Hector Matos. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class OptionsButton: UIButton {
    @IBInspectable var title: String = ""
    @IBInspectable var image: UIImage? {
        didSet {
            let states: [UIControlState] = [.normal, .highlighted, .selected]
            states.forEach { setBackgroundImage(image, for: $0) }
        }
    }
    
    override var isSelected: Bool {
        didSet { layer.borderWidth = isSelected ? 2.0 : 0.0 }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .white
        clipsToBounds = true
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = isSelected ? 2.0 : 0.0
    }
}
