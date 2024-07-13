//
//  KHMainLayoutView.swift
//  cropintegration
//
//  Created by Alex Khuala on 29.03.24.
//

import UIKit

class KHMainLayoutView: KHLayoutView
{
    enum ViewType: CaseIterable
    {
        case topBar
        case content
        case bottomBar
    }
    
    // MARK: - Public
    
    func setView(_ view: KHView, for viewType: ViewType)
    {
        self._entry(for: viewType).setView(view)
        self.setNeedsLayout()
    }
    
    func view(with type: ViewType) -> KHView?
    {
        return self._entries[type]?.view
    }
    
    private(set) var contentViewInset: UIEdgeInsets = .zero
    
    func reload(elementsWith viewTypes: [ViewType]? = nil)
    {
        let viewTypes = viewTypes ?? ViewType.allCases
        for viewType in viewTypes {
            if  let subview = self._entries[viewType]?.view as? KHView_Reloadable {
                subview.reloadContent()
            }
        }
        
        self.setNeedsLayout()
    }
    
    // MARK: - Content
    
    override func updateColors()
    {
        self.backgroundColor = KHTheme.color.back
        self._entries.values.forEach { KHColorSensitiveTools.updateColors(of: $0.view) }
    }
    
    override func layout(with contentInset: UIEdgeInsets)
    {
        self._recentContentInset = contentInset
        
        let mainInset = KHStyle.mainInset
        var viewInset = UIEdgeInsets()
        
        let barInsetY = KHStyle.barVerticalInset
        let contentInset = contentInset.expand(to: .init(mainInset))
        
        // top bar
        if let entry = self._entries[.topBar], let container = entry.container {
            
            let size = entry.layoutView(.init(self.width, 80), inset: contentInset.bottom(barInsetY).adjust(top: 10))

            container.frame = self.bounds.inframe(size, .top).pixelRound()
            viewInset.top = container.bottom
        }
        
        // bottom bar
        if let entry = self._entries[.bottomBar], let container = entry.container {
            
            let size = entry.layoutView(.init(self.width, 80), inset: contentInset.top(barInsetY + 24).adjust(bottom: barInsetY))

            container.frame = self.bounds.inframe(size, .bottom).pixelRound()
            viewInset.bottom = container.topInverted
        }
        
        
        // content
        if let entry = self._entries[.content], let container = entry.container {
            container.frame = self.bounds.inset(viewInset).pixelRound()
            
            entry.layoutView(container.bounds.size, inset: contentInset.y(0))
        }
        
        self.contentViewInset = viewInset
    }
    
    // MARK: - Internal
    
    
    private var _entries: [ViewType: Entry] = [:]
    private var _recentContentInset: UIEdgeInsets = .zero
    
    private func _entry(for viewType: ViewType) -> Entry
    {
        if  let entry = self._entries[viewType] {
            return entry
        }
        
        let entry = Entry(in: self)
        self._entries[viewType] = entry
        
        return entry
    }
    
    private class Entry
    {
        private(set) weak var view: KHView?
        private(set) weak var container: KHView?
        
        func setView(_ view: KHView)
        {
            guard let container = self.container else {
                return
            }
            
            container.subviews.forEach { $0.removeFromSuperview() }
            container.addSubview(view)
            
            self.view = view
        }
        
        @discardableResult
        func layoutView(_ size: CGSize, inset: UIEdgeInsets) -> CGSize
        {
            guard let view = self.view else {
                return size
            }
            
            view.size = size
            view.forceLayout(inset, options: .sizeToFitHeight)
            
            return view.size
        }
        
        init(in superview: UIView, below view: UIView? = nil)
        {
            let container = KHView(.standard)
            container.clipsToBounds = false
            
            if  let view = view {
                superview.insertSubview(container, belowSubview: view)
            } else {
                superview.addSubview(container)
            }
            
            self.container = container
        }
    }
}

