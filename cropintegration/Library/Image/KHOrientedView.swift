//
//  KHOrientedView.swift
//  cropintegration
//
//  Created by Alex Khuala on 30.08.23.
//

import UIKit

final class KHOrientedView: UIView
{
    var orientation: KHOrientation2?
    {
        didSet {
            guard self.orientation != oldValue else {
                return
            }
            self.setNeedsLayout()
        }
    }
    
    var contentView: UIView?
    {
        didSet {
            guard self.contentView !== oldValue else {
                return
            }
            
            if  let view = oldValue, view.superview === self {
                view.removeFromSuperview()
            }
            
            guard let view = self.contentView else {
                return
            }
            
            view.frame = self._flippingView.bounds
            self._flippingView.insertSubview(view, at: 0)
            view.layoutIfNeeded()
        }
    }
    
    func assignEditorView(_ editorView: UIView)
    {
        guard self._editorView !== editorView else {
            return
        }
        self._editorView = editorView
        
        editorView.frame = self._flippingView.bounds
        self._flippingView.addSubview(editorView)
        editorView.layoutIfNeeded()
    }
    
    @discardableResult
    func removeEditorView() -> UIView?
    {
        guard let editorView = self._editorView else {
            return nil
        }
        self._editorView = nil
        
        if  editorView.superview === self {
            editorView.removeFromSuperview()
        }
        
        return editorView
    }
    
    func updateEditorView(in block: (_ editorView: UIView) -> Void)
    {
        guard let editorView = self._editorView else {
            return
        }
        block(editorView)
    }
    
    // MARK: - Init
    
    init(contentView: UIView?)
    {
        super.init(frame: .standard)
        self.contentView = contentView
        
        if  let view = contentView {
            self._flippingView.addSubview(view)
        }
    }
    
    // MARK: - Layout
    
    final override func layoutSubviews()
    {
        if  self._size != self.size || self._needs {
            self._size  = self.size
            self._needs = false
            self._layout()
        }
    }
    
    final override func setNeedsLayout()
    {
        self._needs = true
        super.setNeedsLayout()
    }
        
    // MARK: - Internal
    
    private var _size: CGSize?
    private var _needs = true
    
    private func _layout()
    {
        let bounds = self.bounds
        
        self._rotationView.transform = self._rotationTransform
        self._rotationView.frame = bounds
            
        self._flippingView.transform = self._flippingTransform
        self._flippingView.frame = self._rotationView.bounds
        
        self.contentView?.frame = self._flippingView.bounds
        self._editorView?.frame = self._flippingView.bounds
    }
    
    // MARK: - Private
    
    private var _editorView: UIView?
        
    private lazy var _rotationView = Self._addContainerView(to: self)
    private lazy var _flippingView = Self._addContainerView(to: self._rotationView)

    private var _rotationTransform: CGAffineTransform
    {
        guard let orientation = self.orientation else {
            return .identity
        }
                
        return .init(rotationAngle: orientation.rotationAngle)
    }

    private var _flippingTransform: CGAffineTransform
    {
        guard let orientation = self.orientation else {
            return .identity
        }
        let scale = orientation.flipScale
        
        return .init(scaleX: scale.x, y: scale.y)
    }
        
    // MARK: - Class Private
    
    static private func _addContainerView(to superview: UIView) -> UIView
    {
        let view = KHEventTransparentView(.standard)
        view.clipsToBounds = false
        
        superview.addSubview(view)
        return view
    }
    
    // MARK: - System
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        guard let editorView = self._editorView else {
            return super.point(inside: point, with: event)
        }
        
        let point = editorView.convert(point, from: self)
        return editorView.point(inside: point, with: event)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
