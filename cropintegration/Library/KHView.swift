//
//  KHView.swift
//  printer
//
//  Created by Alex Khuala on 18.06.22.
//

import UIKit

class KHView: UIView
{
    override init(frame: CGRect = .standard)
    {
        super.init(frame: frame)
    }
    
    convenience init(color: UIColor)
    {
        self.init(frame: .standard)
        self.backgroundColor = color
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    struct LayoutOptions: OptionSet
    {
        let rawValue: Int
        
        static let sizeToFitWidth  = Self(rawValue: 1 << 0) // width should be updated to fit content
        static let sizeToFitHeight = Self(rawValue: 1 << 1) // height should be updated to fit content
    }
    
    var contextMenu: KHContextMenu_Protocol?
    {
        didSet {
            oldValue?.view = nil
            self.contextMenu?.view = self
        }
    }
    
    final override func layoutSubviews()
    {
        if  self._isSizeChanged(self.size) || self._insetRecent != self._inset || self._needs {
            self._needs = false
            self._insetRecent = self._inset
            let options = self._layoutOptions
            self._layoutOptions = []
            self.layout(with: self._inset, options: options)
            self._size = self.size
        }
    }
    
    final override func setNeedsLayout()
    {
        self.setNeedsLayout(nil)
    }
    
    final func setNeedsLayout(_ contentInset: UIEdgeInsets? = nil, options: LayoutOptions? = nil)
    {
        if  let inset = contentInset {
            self._inset = inset
        }
        
        if  let options = options {
            self._layoutOptions = options
        }
        
        self._needs = true
        super.setNeedsLayout()
    }
    
    override func layoutIfNeeded() 
    {
        if  self._needs {
            //
            // !IMPORTANT:
            //
            // this must be done to let subviews that had "setNeedsLayout"
            // before to be layout inside animation. Without this call
            // such subviews will layout async only after animation start
            //
            // Example:
            // subview.setNeedsLayout()
            // rootView.setNeedslayout()
            //
            // UIView.animated {
            //     rootView.layoutIfNeeded()
            // }
            //
            // without this duplicating call super.setNeedsLayout(),
            // subview will not animate layout inside root view layout method
            //
            
            super.setNeedsLayout()
        }
        super.layoutIfNeeded()
    }
    
    final func layoutIfNeeded(_ contentInset: UIEdgeInsets)
    {
        guard contentInset != self._inset else {
            self.layoutIfNeeded()
            return
        }
        self.setNeedsLayout(contentInset)
        super.layoutIfNeeded()
    }
    
    final func forceLayout(_ contentInset: UIEdgeInsets? = nil, options: LayoutOptions? = nil)
    {
        self.setNeedsLayout(contentInset, options: options)
        self.layoutIfNeeded()
    }
    
    // MARK: - Overridable methods
    
    func layout(with contentInset: UIEdgeInsets, options: LayoutOptions)
    {
    }
    
    // MARK: - Internal
    
    private var _size: CGSize?
    private var _needs = true
    private var _inset: UIEdgeInsets = .zero
    private var _insetRecent: UIEdgeInsets = .zero
    private var _layoutOptions: LayoutOptions = []
    
    private func _isSizeChanged(_ newSize: CGSize) -> Bool
    {
        guard let oldSize = self._size else {
            return true
        }
        
        guard abs(oldSize.width - newSize.width) < Self._zero else {
            return true
        }
        
        guard abs(oldSize.height - newSize.height) < Self._zero else {
            return true
        }
        
        return false
    }
    
    static private let _zero: CGFloat = 0.0001
}
