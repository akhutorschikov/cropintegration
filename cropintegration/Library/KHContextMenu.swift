//
//  KHContextMenu.swift
//  cropintegration
//
//  Created by Alex Khuala on 12.07.23.
//

import UIKit

protocol KHContextMenu_ContentProvider
{
    associatedtype ActionType: KHContextMenu_ActionType
    
    func contextActions(for view: UIView?) -> [ActionType]
    func didCallContextAction(_ adapter: inout KHContextMenu<Self>.ActionAdapter)
    
    // optional
    
    func contextPreviewController(for view: UIView?) -> UIViewController?
    
    func contextMenuWillBeginPresenting(for view: UIView?)
    func contextMenuAnimatingDismissing(for view: UIView?)
}

extension KHContextMenu_ContentProvider
{
    func contextPreviewController(for view: UIView?) -> UIViewController? { nil }
    
    func contextMenuWillBeginPresenting(for view: UIView?) {}
    func contextMenuAnimatingDismissing(for view: UIView?) {}
}

protocol KHContextMenu_ActionType: Equatable
{
    var details: KHContextMenuActionDetails { get }
}

struct KHContextMenuActionDetails
{
    enum ImageName
    {
        case bundle(String)
        case system(String)
    }
    
    let title: String
    let subtitle: String?
    let imageName: ImageName?
    let attributes: UIMenuElement.Attributes
    
    init(_ title: String, _ subtitle: String?, _ imageName: ImageName?, attributes: UIMenuElement.Attributes = [])
    {
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
        self.attributes = attributes
    }
}

protocol KHContextMenu_Protocol: AnyObject
{
    // use during context menu changes to avoid breaking animations
    var paused: Bool { get set }

    var view: UIView? { get set }
}

class KHContextMenu<ContentProvider: KHContextMenu_ContentProvider>: KHContextMenu_Protocol
{
    struct ActionAdapter
    {
        init(action: ContentProvider.ActionType, view: UIView?)
        {
            self.action = action
            self.view = view
            self.animationBox = .init()
        }
        
        let action: ContentProvider.ActionType
        weak var view: UIView?
        
        var fadeOnHide: Bool = false
        
        var animationRegistry: KHAnimationBox.Registry
        {
            self.animationBox.registry
        }
        
        fileprivate let animationBox: KHAnimationBox
    }

    var paused: Bool
    {
        get {
            self._coordinator.paused
        }
        set {
            self._coordinator.paused = newValue
        }
    }
    
    weak var view: UIView?
    {
        didSet {
            oldValue?.removeInteraction(self._interaction)
            self.view?.addInteraction(self._interaction)
        }
    }
    
    // MARK: - Init
    
    init(with contentProvider: ContentProvider)
    {
        self._contentProvider = contentProvider
    }
    
    // MARK: - Private
    
    fileprivate let _contentProvider: ContentProvider
    
    private lazy var _coordinator: KHContextMenuCoordinator = .init(with: self)
    private lazy var _interaction: UIContextMenuInteraction = .init(delegate: self._coordinator)
    
    fileprivate func _createAdapter(with action: ContentProvider.ActionType) -> ActionAdapter
    {
        return .init(action: action, view: self.view)
    }
}


// *************************
// *************************
// *************************


fileprivate class KHContextMenuCoordinator<ContentProvider: KHContextMenu_ContentProvider>: NSObject, UIContextMenuInteractionDelegate
{
    typealias ContextMenu = KHContextMenu<ContentProvider>
    
    init(with parent: ContextMenu)
    {
        self._parent = parent
    }
    
    fileprivate var paused = false
    
    // MARK: - Interaction Delegate
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
    {
        guard !self.paused else {
            return nil
        }
        
        return UIContextMenuConfiguration(previewProvider: { [weak self] in
            
            guard let parent = self?._parent else {
                return nil
            }
            
            return parent._contentProvider.contextPreviewController(for: parent.view)
                        
        }, actionProvider:  { [weak self] _ in
            
            var children: [UIMenuElement] = []
            
            if  let parent = self?._parent {
                for action in parent._contentProvider.contextActions(for: parent.view) {
                    children.append(Self._createAction(for: action, handler: { [weak self] _ in
                        guard let coordinator = self, let parent = coordinator._parent else {
                            return
                        }
                        
                        var adapter = parent._createAdapter(with: action)
                        parent._contentProvider.didCallContextAction(&adapter)
                        coordinator._adapter = adapter
                    }))
                }
            }
            
            return UIMenu(title: "", children: children)
        })
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?)
    {
        if  let parent = self._parent {
            parent._contentProvider.contextMenuWillBeginPresenting(for: parent.view)
        }
        
        self._adapter = nil
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?)
    {
        guard let animator = animator else {
            return
        }
        
        var needsAnimatingDismissing = true
        if  let adapter = self._adapter {
            let box = adapter.animationBox
            if  box.hasAnimations() {
                needsAnimatingDismissing = false
                animator.addAnimations {
                    box.executeAnimations(reset: true)
                }
            }
            if  box.hasCompletions() {
                animator.addCompletion {
                    box.executeCompletions(reset: true)
                }
            }
        }
        
        if  needsAnimatingDismissing {
            animator.addAnimations { [weak self] in
                if  let parent = self?._parent {
                    parent._contentProvider.contextMenuAnimatingDismissing(for: parent.view)
                }
            }
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, dismissalPreviewForItemWithIdentifier identifier: NSCopying) -> UITargetedPreview? 
    {
        guard (self._adapter == nil || !self._adapter!.fadeOnHide), let view = interaction.view, view.superview != nil else {
            return nil
        }
        
        return .init(view: view)
    }
    
    // MARK: - Private
    
    private weak var _parent: ContextMenu?
    
    private var _adapter: KHContextMenu<ContentProvider>.ActionAdapter?
    
    // MARK: - Class Private
    
    private static func _createAction(for type: ContentProvider.ActionType, handler: @escaping (UIAction) -> Void) -> UIAction
    {
        let details = type.details
        
        // image
        let image: UIImage?
        switch details.imageName {
        case .bundle(let name):
            image = UIImage(named: name)
        case .system(let name):
            image = UIImage(systemName: name)
        default:
            image = nil
        }
        
        return .init(title: details.title, subtitle: details.subtitle, image: image, identifier: nil, attributes: details.attributes, handler: handler)
    }
}
