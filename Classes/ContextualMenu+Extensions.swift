//
//  iOSContextualMenu+Extensions.swift
//  iOSContextualMenu
//
//  Created by Hector Matos on 11/29/17.
//

import Foundation
import UIKit

@objc public protocol ContextualMenuDelegate {
    @objc(contextualMenu:viewForMenuItemAtIndex:)
    func contextualMenu(_ menu: ContextualMenu, viewForMenuItemAt index: Int) -> UIView
    
    @objc optional func contextualMenuShouldActivate(_ menu: ContextualMenu) -> Bool
    @objc optional func contextualMenuShouldDismiss(_ menu: ContextualMenu) -> Bool
    @objc optional func contextualMenuDidActivate(_ menu: ContextualMenu)
    @objc optional func contextualMenuDidDismiss(_ menu: ContextualMenu)
    
    @objc(contextualMenu:didSelectItemAtIndex:)
    optional func contextualMenu(_ menu: ContextualMenu, didSelectItemAt index: Int)
    @objc(contextualMenu:didHighlightItemAtIndex:)
    optional func contextualMenu(_ menu: ContextualMenu, didHighlightItemAt index: Int)
    @objc(contextualMenu:didUnhighlightItemAtIndex:)
    optional func contextualMenu(_ menu: ContextualMenu, didUnhighlightItemAt index: Int)
    @objc(contextualMenu:viewForHighlightedMenuItemAtIndex:)
    optional func contextualMenu(_ menu: ContextualMenu, viewForHighlightedMenuItemAt index: Int) -> UIView?
    @objc(contextualMenu:titleForMenuItemAtIndex:)
    optional func contextualMenu(_ menu: ContextualMenu, titleForMenuItemAt index: Int) -> String
    @objc(contextualMenu:titleViewForMenuItemAtIndex:)
    optional func contextualMenu(_ menu: ContextualMenu, titleViewForMenuItemAt index: Int) -> UIView?
}

@objc public protocol ContextualMenuDataSource {
    @objc(numberOfMenuItemsForContextualMenu:)
    func numberOfMenuItems(for menu: ContextualMenu) -> Int
}

@objc public enum MenuType: Int {
    case radial
    case fan
}

@objc public enum ActivateOption: Int {
    case onLongPress
    case onForceTouch
    case onTap
    case asSoonAsPossible
}

extension CGFloat {
    var radians: CGFloat { return self * (.pi / 180.0) }
    var degrees: CGFloat { return self * (180.0 / .pi) }
    var half: CGFloat { return self / 2.0 }
}

extension String {
    var isValid: Bool { return self != nil && !self.isEmpty }
}

extension CGRect {
    static func squareRectFrom(size: CGFloat) -> CGRect {
        return CGRect(origin: .zero, size: CGSize(width: size, height: size))
    }
}

extension CGSize {
    var minValue: CGFloat { return min(width, height) }
    var maxValue: CGFloat { return max(width, height) }
}

extension UIView {
    var largestSide: CGFloat { return frame.size.maxValue }
    
    convenience init(frame: CGRect, backgroundColor: UIColor) {
        self.init(frame: frame)
        self.backgroundColor = backgroundColor
    }
}
