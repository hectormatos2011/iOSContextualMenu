//
//  ContextualMenuItemView.swift
//  iOSContextualMenu
//
//  Created by Hector Matos on 12/7/17.
//

import Foundation
import UIKit

protocol MenuItemDelegate: class {
    func didSelect(menuItemView: ContextualMenuItemView)
    func didHighlight(menuItemView: ContextualMenuItemView)
}

class ContextualMenuItemView: UIView {
    let contentView: UIView
    let highlightedView: UIView
    private let delegate: MenuItemDelegate
    private let overlayButton: ContextualMenuItemOverlayButton
    
    var isHighlighted: Bool {
        get { return overlayButton.isHighlighted }
        set { overlayButton.isHighlighted = newValue }
    }
    override var frame: CGRect {
        didSet { updateCornerRadius() }
    }
    override var bounds: CGRect {
        didSet { updateCornerRadius() }
    }

    required init(contentView: UIView, highlightedView: UIView, delegate: MenuItemDelegate) {
        self.contentView = contentView
        self.highlightedView = highlightedView
        self.overlayButton = ContextualMenuItemOverlayButton(frame: contentView.bounds, backgroundColor: .clear)
        self.overlayButton.delegate = delegate
        self.delegate = delegate
        
        super.init(frame: contentView.bounds)
        
        highlightedView.alpha = 0.0
        clipsToBounds = true
        addSubview(contentView)
        addSubview(highlightedView)
        addSubview(overlayButton)
        
        subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        let xAxisAnchors = subviews.flatMap { [($0.leftAnchor, leftAnchor), (rightAnchor, $0.rightAnchor)] }
        let yAxisAnchors = subviews.flatMap { [($0.topAnchor, topAnchor), (bottomAnchor, $0.bottomAnchor)] }
        NSLayoutConstraint.activate(xAxisAnchors.map(constraint) + yAxisAnchors.map(constraint))
        
        overlayButton.addTarget(self, action: #selector(didTapOverlayButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCornerRadius() {
        layer.cornerRadius = bounds.size.minValue.half
    }

    func constraint<T>(_ lhs: NSLayoutAnchor<T>, _ rhs: NSLayoutAnchor<T>) -> NSLayoutConstraint {
        return lhs.constraint(equalTo: rhs)
    }
    
    @objc func didTapOverlayButton() {
        delegate.didSelect(menuItemView: self)
    }
}

private class ContextualMenuItemOverlayButton: UIButton {
    weak var delegate: MenuItemDelegate?
    override var isHighlighted: Bool {
        didSet {
            guard let superview = superview as? ContextualMenuItemView else { return }
            guard oldValue != isHighlighted else { return }
            delegate?.didHighlight(menuItemView: superview)
        }
    }
}
