//
//  ContextualMenu.swift
//  iOSContextualMenu
//
//  Created by Hector Matos on 11/14/17.
//

import Foundation
import UIKit

public class ContextualMenu: UIView {
    typealias ContextualMenuItem = (mainItem: ContextualMenuItemView, titleView: UIView, index: Int)
    
    fileprivate struct ScreenEdge: OptionSet {
        let rawValue: UInt
        
        static let left  = ScreenEdge(rawValue: 1 << 0)
        static let right = ScreenEdge(rawValue: 1 << 1)
        static let top   = ScreenEdge(rawValue: 1 << 2)
    }
    
    /// Defaults to false. This flag determines whether or not the menu item will animate outwards on highlight. Or just stay in place.
    @objc public var shouldHighlightOutwards = false

    /// Distance of each menuItem from the edge of the startingCircle (the thing that indicates your touch). Lower values bring all the menu items closer to the center and higher values push them further from the center. Defaults to 30 pts.
    @objc public var menuItemDistancePadding: CGFloat = 30.0
    
    /// Set this to switch between how the menu items are spaced from each other.
    @objc public var menuType: MenuType = .fan
    
    /// Set this to switch between ways to activate the menu later on.
    @objc public var activateOption: ActivateOption = .onTap {
        didSet {
            updateRecognizers()
            if activateOption == .asSoonAsPossible, let superview = superview, window != nil {
                presentMenuItems(at: superview.convert(CGPoint(x: superview.bounds.width.half, y: superview.bounds.height.half), to: nil))
            }
        }
    }
    
    /// Defaults to Helvetica Neue Thin (13pt). If you use contextualMenu(_:titleForMenuItemAt:), this will be the font of the label created above each menu item that's shown when the menuItem is highlighted.
    @objc public var titleViewFont = UIFont(name: "HelveticaNeue-Thin", size: 13.0)
    
    @objc public weak var delegate: ContextualMenuDelegate?
    @objc public weak var dataSource: ContextualMenuDataSource?
    
    fileprivate let shadowView: UIView
    fileprivate let startCircleView: UIView
    
    fileprivate let circleViewSize: CGFloat = 50.0
    fileprivate let startCircleStrokeWidth: CGFloat = 4.0
    fileprivate let topAndBottomTitleLabelPadding: CGFloat = 5.0
    fileprivate let titleLabelPadding: CGFloat = 2.5

    fileprivate let tapGesture = UITapGestureRecognizer()
    fileprivate let longPressGesture = UILongPressGestureRecognizer()
    fileprivate let forceTouchGesture = ForceTouchGestureRecognizer()

    fileprivate var startingLocation: CGPoint = .zero
    fileprivate var contextualMenuItems: [ContextualMenuItem] = []
    
    @objc public required init(menuType: MenuType = .fan, activate activateOption: ActivateOption = .onLongPress) {
        self.menuType = menuType
        self.activateOption = activateOption
        
        shadowView = UIView(frame: .zero)
        shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        shadowView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        shadowView.alpha = 0.0
        
        startCircleView = UIView(frame: .squareRectFrom(size: circleViewSize))
        startCircleView.backgroundColor = .clear
        startCircleView.layer.cornerRadius = circleViewSize.half
        startCircleView.layer.borderColor = UIColor.white.withAlphaComponent(0.75).cgColor
        startCircleView.layer.borderWidth = startCircleStrokeWidth
        
        let shadowDismissButton = UIButton(frame: shadowView.bounds, backgroundColor: .clear)
        shadowDismissButton.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        shadowView.addSubview(shadowDismissButton)
        shadowView.addSubview(startCircleView)
        
        super.init(frame: .zero)
        
        shadowDismissButton.addTarget(self, action: #selector(dismissMenuItems), for: .touchUpInside)
        tapGesture.addTarget(self, action: #selector(handleGesture(recognizer:)))
        longPressGesture.addTarget(self, action: #selector(handleGesture(recognizer:)))
        forceTouchGesture.addTarget(self, action: #selector(handleGesture(recognizer:)))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateRecognizers()
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        
        var rootController = window?.rootViewController
        while let presentedViewController = rootController?.presentedViewController {
            rootController = presentedViewController
        }
        shadowView.frame = rootController?.view.bounds ?? .zero
        rootController?.view.addSubview(shadowView)
        
        if let superview = superview, activateOption == .asSoonAsPossible {
            presentMenuItems(at: superview.convert(CGPoint(x: superview.bounds.width.half, y: superview.bounds.height.half), to: nil))
        }
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitTest = super.hitTest(point, with: event)
        guard let superview = superview else { return hitTest }
        
        let locationInWindow = superview.convert(point, to: nil)
        startingLocation = CGPoint(x: (locationInWindow.x - point.x) + superview.bounds.midX, y: (locationInWindow.y - point.y) + superview.bounds.midY)
        return hitTest
    }
    
    private func updateRecognizers() {
        recognizerOptionPairs.forEach {
            $0.recognizer.view?.removeGestureRecognizer($0.recognizer)
            superview?.addGestureRecognizer($0.recognizer)
            $0.recognizer.isEnabled = $0.option == activateOption
        }
        startCircleView.isHidden = activateOption != .onLongPress && activateOption != .onForceTouch
        superview?.isUserInteractionEnabled = superview?.isUserInteractionEnabled == true || activateOption != .asSoonAsPossible;
    }
}

// MARK: Public API
extension ContextualMenu {
    @objc public func reloadData() {
        contextualMenuItems.forEach(removeAssociatedViews)
        contextualMenuItems.removeAll()
        
        let menuItemCount = dataSource?.numberOfMenuItems(for: self)
        guard let delegate = self.delegate, let itemCount = menuItemCount else { return }
        
        contextualMenuItems = (0..<itemCount).map { index in
            let menuItemView = delegate.contextualMenu(self, viewForMenuItemAt: index)
            let highlightedView = delegate.contextualMenu?(self, viewForHighlightedMenuItemAt: index) ?? UIView(frame: menuItemView.bounds, backgroundColor: UIColor(white: 0.0, alpha: 0.7))
            let titleView = delegate.contextualMenu?(self, titleViewForMenuItemAt: index) ?? defaultTitleViewForMenuItem(at: index)
            return (ContextualMenuItemView(contentView: menuItemView, highlightedView: highlightedView, delegate: self), titleView, index)
        }
        contextualMenuItems.flatMap { [$0.mainItem, $0.titleView] }.forEach {
            $0.center = startingLocation
            $0.alpha = 0.0
            shadowView.addSubview($0)
        }
    }
}

// MARK: Gesture Handling
extension ContextualMenu {
    @objc func handleGesture(recognizer: UIGestureRecognizer) {
        let touchLocation = recognizer.location(in: nil)
        if recognizer.state == .began || recognizer is UITapGestureRecognizer {
            presentMenuItems(at: touchLocation)
        } else if recognizer.state == .changed {
            handleDrag(with: touchLocation)
        } else if recognizer.state == .ended || recognizer.state == .cancelled {
            guard let highlightedMenuItem = currentlyHighlightedItem else {
                dismissMenuItems()
                return
            }
            didSelect(menuItemView: highlightedMenuItem.mainItem)
        }
    }
    
    func handleDrag(with location: CGPoint) {
        let innerCircleRectX = startingLocation.x - menuItemDistancePadding
        let innerCircleRadius = startingLocation.x - innerCircleRectX
        let angleOfGestureLocation = getAngle(between: startingLocation, and: location)
        let currentDistanceFromOrigin = distance(from: location, to: startingLocation)
        let distanceFromOrigin = min(currentDistanceFromOrigin, menuItemsCenterRadius)
        let touchLocation = currentDistanceFromOrigin > menuItemsCenterRadius ? locationOnCircleCircumference(radius: menuItemsCenterRadius, angle: angleOfGestureLocation, origin: startingLocation) : location
        defer { startCircleView.center = touchLocation }
        
        // If the touch location isn't within the concentric circle that contains the actual menu items, then we don't care to proceed.
        guard innerCircleRadius <= distanceFromOrigin else {
            contextualMenuItems.forEach { $0.mainItem.isHighlighted = false }
            return
        }
        
        // If the touch location is too far from a menuItem, then we don't care to proceed.
        let locationOnCircle = locationOnCircleCircumference(radius: menuItemsCenterRadius, angle: angleOfGestureLocation, origin: startingLocation)
        guard let item = item(closestTo: locationOnCircle), distance(from: item.mainItem.center, to: locationOnCircle) <= item.mainItem.bounds.height else {
            contextualMenuItems.forEach { $0.mainItem.isHighlighted = false }
            return
        }
        shadowView.bringSubview(toFront: item.mainItem)
        shadowView.bringSubview(toFront: item.titleView)
        currentlyHighlightedItem?.mainItem.isHighlighted = currentlyHighlightedItem?.mainItem == item.mainItem
        item.mainItem.isHighlighted = true
    }
}

// MARK: MenuItemDelegate
extension ContextualMenu: MenuItemDelegate {
    func didHighlight(menuItemView: ContextualMenuItemView) {
        guard let menuItem = item(matching: menuItemView) else { return }
        let radiusOffset = menuItemView.isHighlighted ? highlightRadiusOffset : 0.0
        let newRadius = menuItemsCenterRadius + radiusOffset
        let newCenter = centerForMenuItem(at: menuItem.index, radius: newRadius)
        animate(item: menuItem, to: newCenter)
        
        if menuItemView.isHighlighted {
            delegate?.contextualMenu?(self, didHighlightItemAt: menuItem.index)
        } else {
            delegate?.contextualMenu?(self, didUnhighlightItemAt: menuItem.index)
        }
    }
    
    func didSelect(menuItemView: ContextualMenuItemView) {
        guard let menuItem = item(matching: menuItemView) else { return }
        delegate?.contextualMenu?(self, didSelectItemAt: menuItem.index)
        dismissMenuItems()
    }
}

// MARK: Animation Functions
extension ContextualMenu {
    func presentMenuItems(at location: CGPoint) {
        startingLocation = location
        startCircleView.center = location
        reloadData()
        
        guard delegate?.contextualMenuShouldActivate?(self) != false && !contextualMenuItems.isEmpty && shadowView.alpha == 0.0 && window != nil else { return }
        
        delegate?.contextualMenuDidActivate?(self)
        shadowView.superview?.bringSubview(toFront: shadowView)

        for item in contextualMenuItems {
            item.titleView.center = CGPoint(x: startingLocation.x, y: item.mainItem.frame.minY + item.titleView.frame.height.half)
        }
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0.0, options: [.calculationModeCubic], animations: {
            self.shadowView.alpha = 1.0
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.8) {
                for item in self.contextualMenuItems {
                    let menuItem = item.mainItem
                    let titleView = item.titleView
                    menuItem.alpha = 1.0
                    menuItem.center = self.centerForMenuItem(at: item.index, radius: self.totalCircleRadius)
                    titleView.center = CGPoint(x: menuItem.center.x, y: menuItem.frame.minY + titleView.frame.height.half)
                }
            }
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
                for item in self.contextualMenuItems {
                    let menuItem = item.mainItem
                    let titleView = item.titleView
                    menuItem.center = self.centerForMenuItem(at: item.index, radius: self.menuItemsCenterRadius)
                    titleView.center = CGPoint(x: menuItem.center.x, y: menuItem.frame.minY + titleView.frame.height.half)
                }
            }
        }, completion: nil)
    }

    @objc func dismissMenuItems() {
        guard delegate?.contextualMenuShouldDismiss?(self) ?? true else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.shadowView.alpha = 0.0
            self.contextualMenuItems.flatMap { [$0.mainItem, $0.titleView] }.forEach {
                $0.center = self.startingLocation
                $0.alpha = 0.0
            }
        }, completion: { _ in
            self.delegate?.contextualMenuDidDismiss?(self)
        })
    }
    
    func animate(item: ContextualMenuItem, to location: CGPoint) {
        shadowView.bringSubview(toFront: item.titleView)

        let menuItem = item.mainItem
        let titleView = item.titleView
        let highlightedView = menuItem.highlightedView
        let alpha: CGFloat = menuItem.isHighlighted ? 1.0 : 0.0
        let titleLabelPadding = menuItem.isHighlighted ? self.titleLabelPadding : 0.0
        let titleLabelOvershoot: CGFloat = menuItem.isHighlighted ? 7.0 : 0.0
        let titleLabelCenterMultiplier: CGFloat = menuItem.isHighlighted ? -1.0 : 1.0
        
        highlightedView.alpha = menuItem.isHighlighted ? 0.0 : 1.0

        UIView.animateKeyframes(withDuration: 0.2, delay: 0.0, options: .beginFromCurrentState, animations: {
            titleView.alpha = alpha
            highlightedView.alpha = alpha
            menuItem.center = location

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.7) {
                titleView.center = CGPoint(x: location.x, y: titleLabelCenterMultiplier * (titleView.frame.height.half + titleLabelPadding + titleLabelOvershoot) + menuItem.frame.minY)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
                titleView.center = CGPoint(x: location.x, y: titleLabelCenterMultiplier * (titleView.frame.height.half + titleLabelPadding) + menuItem.frame.minY)
            }
            
            // menuItem scaling keyframes
            guard menuItem.isHighlighted else { return }
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2) {
                menuItem.transform = CGAffineTransform.identity.scaledBy(x: 1.2, y: 1.2)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.6) {
                menuItem.transform = CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                menuItem.transform = .identity
            }
        }, completion: nil)
    }
}

// MARK: Computed Variables
extension ContextualMenu {
    fileprivate var defaultStartingAngle: CGFloat { return -angleIncrement }
    fileprivate var angleIncrement: CGFloat { return 360.0 / CGFloat(maxMenuItemCount) }
    fileprivate var highlightRadiusOffset: CGFloat { return shouldHighlightOutwards ? 25.0 : 0.0 }
    fileprivate var totalCircleRadius: CGFloat { return startingLocation.x - entireMenuOriginX }
    fileprivate var menuItemsCenterRadius: CGFloat { return totalCircleRadius - biggestMenuItemSize.half }
    fileprivate var maxMenuItemCount: Int {
        return menuType == .fan ? max(contextualMenuItems.count, 8) : contextualMenuItems.count
    }
    fileprivate var currentlyHighlightedItem: ContextualMenuItem? {
        return contextualMenuItems.first { $0.mainItem.isHighlighted }
    }
    fileprivate var entireMenuOriginX: CGFloat {
        return startingLocation.x - circleViewSize.half - menuItemDistancePadding - biggestMenuItemSize
    }
    fileprivate var recognizerOptionPairs: [(recognizer: UIGestureRecognizer, option: ActivateOption)] {
        return [(tapGesture, .onTap), (longPressGesture, .onLongPress), (forceTouchGesture, .onForceTouch)]
    }
    fileprivate var biggestMenuItemSize: CGFloat {
        return contextualMenuItems.reduce(0.0) { max($0, $1.mainItem.largestSide) }
    }
    fileprivate var biggestTitleViewSize: CGSize {
        return contextualMenuItems.reduce(.zero) {
            CGSize(width: max($0.width, $1.mainItem.frame.width), height: max($0.height, $1.mainItem.frame.height))
        }
    }
    fileprivate var topUnsafeAreaLength: CGFloat {
        if #available(iOS 11.0, *) {
            return shadowView.safeAreaInsets.top
        } else {
            return UIApplication.shared.isStatusBarHidden ? 0.0 : UIApplication.shared.statusBarFrame.height
        }
    }
    fileprivate var screenEdge: ScreenEdge {
        // Calculate proper angle offset
        var screenCorner: ScreenEdge = startingLocation.x < shadowView.bounds.midX ? .left : .right;
        
        if (startingLocation.y - totalCircleRadius - highlightRadiusOffset - titleLabelPadding - biggestTitleViewSize.height < topUnsafeAreaLength) {
            // The highest possible y is past the top screen edge.
            screenCorner.insert(.top)
        }
        return screenCorner
    }
    fileprivate var angleOffset: CGFloat {
        /// MAGIC. DO NOT TOUCH/EDIT LEST DRAGONS EAT YOU ALIVE
        var offset: CGFloat = 0.0
        guard !contextualMenuItems.isEmpty else { return offset }
        
        // If the user has touched too close to the edge of the screen, the menu item closest to the screen edge and it's label could bleed past it. We want to prevent this so we need to calculate an angle offset amount to apply to the starting angle of the first menu item.
        
        // First, we need to find the furthest point from the center of the user's starting location. The highlighted state is the furthest so let's make calculations based off of that.
        let circleRadius = menuItemsCenterRadius + highlightRadiusOffset
        
        // This center point is where the menu item would have started at before the angle offset is applied.
        
        let startingAngle = screenEdge.contains(.left) ? defaultStartingAngle + 360.0 : defaultStartingAngle + (CGFloat(contextualMenuItems.count - 1) * angleIncrement)
        let highlightedMenuCenter = locationOnCircleCircumference(radius: circleRadius, angle: startingAngle, origin: startingLocation)
        
        // how far from the y axis do we want the edge of the label to be?
        let screenEdgeOffsetForFinalLabelPosition: CGFloat = 10.0
        
        // To determine the furthest point of the label in relation to the screen's edge, we need to first determine which label size to use based on which half of the screen we're on. Left half would be the labelsize of the label of the menu item at index 1. Right half would be the label of the menu item at the last index of the menu item array.
        // Calculation defaults are for left edge.
        // Can use implicitly unwrapped optional since this function is guarded by a count check so there will always be a value from .first or .last
        let menuItemClosestToEdge = screenEdge.contains(.right) ? contextualMenuItems.last! : contextualMenuItems.first!
        let sizeOfClosestLabelToEdge = menuItemClosestToEdge.titleView.frame.size
        let maxWidthForFurthestX = max(sizeOfClosestLabelToEdge.width, biggestMenuItemSize)
        let labelXFurthestFromTheEdge = highlightedMenuCenter.x - maxWidthForFurthestX.half
        var calculateAngleOffset = labelXFurthestFromTheEdge < screenEdgeOffsetForFinalLabelPosition
        
        // Inverse calculations for cases where the touch is on the right half of the screen.
        if screenEdge.contains(.right) {
            calculateAngleOffset = (highlightedMenuCenter.x + maxWidthForFurthestX.half > shadowView.bounds.width - screenEdgeOffsetForFinalLabelPosition)
        }
        
        if calculateAngleOffset {
            // Since we want the label of the closest menu item to the screen edge to be flush with the screen edge, we can derive the x of where that menu item is supposed to be from that label. (NOTE: each menu item's label is centered with the menu item. So the center.x of the label is equal to the center.x of the menu item.) Once we know that X, we can use the parametric equation to derive the angle of that final position of said menu item in relation to the origin.
            var finalCenterXOfMenuItemClosestToEdge = screenEdgeOffsetForFinalLabelPosition + maxWidthForFurthestX.half
            if screenEdge.contains(.right) {
                finalCenterXOfMenuItemClosestToEdge = shadowView.frame.width - maxWidthForFurthestX.half - screenEdgeOffsetForFinalLabelPosition
            }
            
            let knownLegWidth = finalCenterXOfMenuItemClosestToEdge - startingLocation.x
            let missingSideLength = calculateMissingSideOfTriangle(hypotenuse: circleRadius, knownLegWidth: knownLegWidth)
            let wantedStartingMenuItemCenter = CGPoint(x: finalCenterXOfMenuItemClosestToEdge, y: startingLocation.y - missingSideLength)
            let finalAngleOfMenuItemClosestToEdge = getAngle(between: startingLocation, and: wantedStartingMenuItemCenter)
            
            // Subtract the startingAngle from the angle of the final menu item's position, and we have our angle offset!
            offset = finalAngleOfMenuItemClosestToEdge - startingAngle
        }
        
        if screenEdge.contains(.top) {
            // We have a menu item crossing the top edge, so let's offset it instead by doing the same thing as above, but instead of making calculations based off of the x where we want the starting menu item to be, we use the y.
            // Parametric equation for y value on a circle's circumference is y = originY - (radius * cos(angle))
            // Solve for theta!
            // angle = acos((originY - y) / radius)
            
            let multiplier: CGFloat = screenEdge.contains(.right) ? -1.0 : 1.0
            let wantedCenterYOfMenuItemClosestToTopEdge = max(screenEdgeOffsetForFinalLabelPosition, topUnsafeAreaLength) + sizeOfClosestLabelToEdge.height + titleLabelPadding + biggestMenuItemSize.half
            let knownLegWidth = startingLocation.y - wantedCenterYOfMenuItemClosestToTopEdge
            let lengthOfMissingTriangleLeg = calculateMissingSideOfTriangle(hypotenuse: circleRadius, knownLegWidth: knownLegWidth) * multiplier
            let wantedCenterX = startingLocation.x + lengthOfMissingTriangleLeg
            let wantedStartingMenuItemCenter = CGPoint(x: wantedCenterX, y: wantedCenterYOfMenuItemClosestToTopEdge)
            let wantedAngleOfMenuItemClosestToTopEdge = getAngle(between: startingLocation, and: wantedStartingMenuItemCenter)
            offset = wantedAngleOfMenuItemClosestToTopEdge - startingAngle
        }
        return offset
    }
}

// MARK: Geometric/Convenience Functions
extension ContextualMenu {
    fileprivate func item(matching menuItemView: ContextualMenuItemView) -> ContextualMenuItem? {
        return contextualMenuItems.first { $0.mainItem == menuItemView }
    }
    
    fileprivate func item(closestTo locationOnCircumference: CGPoint) -> ContextualMenuItem? {
        return contextualMenuItems.min {
            let firstCenter = centerForMenuItem(at: $0.index, radius: menuItemsCenterRadius)
            let secondCenter = centerForMenuItem(at: $1.index, radius: menuItemsCenterRadius)
            let firstDistance = distance(from: firstCenter, to: locationOnCircumference)
            let secondDistance = distance(from: secondCenter, to: locationOnCircumference)
            return firstDistance < secondDistance
        }
    }
    
    /// Determines the angle of a straight line drawn between firstPoint and secondPoint relative to the x axis in degrees. To get it in Radians, return the 'radians' instance variable.
    fileprivate func getAngle(between origin: CGPoint, and secondPoint: CGPoint) -> CGFloat {
        // Because this formula returns the angle of the straight line between firstPoint and secondPoint relative to the X axis, where a horizontal line gives a value of 0 degrees and a vertical line gives a value of -90 degrees (because iOS has a flipped y coordinate system), we have to add 90 degrees to make the final output relative to the y axis.
        let angle = atan2(secondPoint.y - origin.y, secondPoint.x - origin.x).degrees + 90.0
        
        // After 270 degrees, angle jumps to -90 degrees. Adding 360 degrees to that will get us the correct angle from 270 to 360.
        return angle < 0.0 ? angle + 360.0 : angle
    }
    
    /// Uses the distance formula to calculate the distance of any point (the user's touch) from the origin (the starting location). We leverage this to see if the user's touch is inside of the concentric circle that the menu items are inside of.
    func distance(from point: CGPoint, to origin: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - origin.x, 2.0) + pow(point.y - origin.y, 2.0));
    }
    
    /// Using the parametric equation, we can determine the point along the line of the circumference of a circle given it's radius and the angle of which to space out each point relative to the x axis.
    func locationOnCircleCircumference(radius: CGFloat, angle: CGFloat, origin: CGPoint) -> CGPoint {
        // Parametric Equation
        // angle is in radians
        // x = origin.x + (radius * sin(angle))
        // y = origin.y + (radius * cos(angle))
        
        // For iOS, the coordinate system flips the y so we need to make y negative.
        // This changes the parametric equation to using subtraction for the y instead
        return CGPoint(
            x: origin.x + (radius * sin(angle.radians)),
            y: origin.y - (radius * cos(angle.radians))
        )
    }

    func centerForMenuItem(at index: Int, radius: CGFloat) -> CGPoint {
        let startingAngle = defaultStartingAngle + (CGFloat(index) * angleIncrement) + angleOffset;
        return locationOnCircleCircumference(radius: radius, angle: startingAngle, origin: startingLocation)
    }

    func calculateMissingSideOfTriangle(hypotenuse: CGFloat, knownLegWidth: CGFloat) -> CGFloat {
        // a^2 + b^2 = c^2 - solve for b
        // b = squareRoot(c^2 - a^2)
        
        // Let's ensure our hypotenuse is greater than our legA
        let newHypotenuse = max(abs(knownLegWidth), abs(hypotenuse))
        let legA = min(abs(knownLegWidth), abs(newHypotenuse))
        return sqrt(pow(newHypotenuse, 2.0) - pow(legA, 2.0))
    }
    
    func removeAssociatedViews(_ item: ContextualMenuItem) {
        item.mainItem.removeFromSuperview()
        item.titleView.removeFromSuperview()
    }
    
    func defaultTitleViewForMenuItem(at index: Int) -> UIView {
        guard let text = delegate?.contextualMenu?(self, titleForMenuItemAt: index), !text.isEmpty else {
            return UIView(frame: .squareRectFrom(size: 1.0), backgroundColor: .clear)
        }
        
        let titleLabel = UILabel()
        titleLabel.text = text
        titleLabel.textColor = .black
        titleLabel.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        titleLabel.font = titleViewFont
        titleLabel.alpha = 0.0
        titleLabel.clipsToBounds = true
        titleLabel.sizeToFit()

        let labelHeight = titleLabel.frame.height + (topAndBottomTitleLabelPadding * 2.0)
        let labelWidth = titleLabel.frame.width + (labelHeight * 0.8)
        titleLabel.frame = CGRect(origin: .zero, size: CGSize(width: labelWidth, height: labelHeight))
        titleLabel.layer.cornerRadius = titleLabel.frame.height.half
        return titleLabel
    }
}
