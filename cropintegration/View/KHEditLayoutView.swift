//
//  KHEditLayoutView.swift
//  cropintegration
//
//  Created by Alex Khuala on 30.08.23.
//

import UIKit

class KHEditLayoutView: KHLayoutView
{
    enum ViewType: CaseIterable
    {
        case topBar
        case editor
        case bottomBar
    }
    
    var editing: Bool = false
    {
        didSet {
            self.updateColors()
            self.forceLayout()
        }
    }
    
    func setView(_ view: KHView, for viewType: ViewType)
    {
        self._entry(for: viewType).setView(view)
        self.setNeedsLayout()
    }
    
    func view(with type: ViewType) -> KHView?
    {
        return self._entries[type]?.view
    }
    
    // MARK: - Content
    
    override func updateColors()
    {
        self.backgroundColor = self.editing ? KHTheme.color.back : .clear
        self._entries.values.forEach { KHColorSensitiveTools.updateColors(of: $0.view) }
        
        self._entries[.topBar]?.visible = self.editing
        self._entries[.bottomBar]?.visible = self.editing
    }
    
    override func layout(with contentInset: UIEdgeInsets)
    {
        let mainInset = KHStyle.mainInset
        var viewInset = UIEdgeInsets()
        
        let barInsetY = KHStyle.barVerticalInset
        let contentInset = contentInset.expand(to: .init(mainInset))
        
        // header
        if let entry = self._entries[.topBar], let container = entry.container {
            
            let size = entry.layoutView(.init(self.width, 80), inset: contentInset.bottom(barInsetY).adjust(top: 6))

            container.frame = self.bounds.inframe(size, .top).pixelRound()
            viewInset.top = container.bottom
        }
        
        // footer
        if let entry = self._entries[.bottomBar], let container = entry.container {
            
            let size = entry.layoutView(.init(self.width, contentInset.bottom + 70), inset: contentInset.top(0) - .init(x: 5))

            container.frame = self.bounds.inframe(size, .bottom).pixelRound()
            viewInset.bottom = container.topInverted
        }
        
        // middle
        if let entry = self._entries[.editor], let container = entry.container {
            container.frame = self.bounds.inset(viewInset).pixelRound()
            
            if  let view = entry.view {
                view.frame = container.bounds
                view.forceLayout(contentInset.y(0))
            }
        }
    }
    
    // MARK: - Internal
    
    private var _entries: [ViewType: Entry] = [:]
    
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
        
        fileprivate var visible: Bool = false
        {
            didSet {
                self.container?.alpha = self.visible ? 1 : 0
            }
        }
        
        func setView(_ view: KHView)
        {
            guard let container = self.container else {
                return
            }
            
            container.subviews.forEach { $0.removeFromSuperview() }
            container.addSubview(view)
            
            self.view = view
        }

        
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
            
            if let view = view {
                superview.insertSubview(container, belowSubview: view)
            } else {
                superview.addSubview(container)
            }
            
            self.container = container
        }
    }
}
