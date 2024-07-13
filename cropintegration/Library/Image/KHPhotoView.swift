//
//  KHPhotoView.swift
//  kh-kit
//
//  Created by Alex Khuala on 31.08.23.
//

import UIKit

protocol KHPhotoContent_View: KHView
{
    var selected: Bool { get set }
    var identifier: Int { get set }
}

class KHPhotoView: KHView, KHPhotoContent_View
{
    // MARK: - Init
    
    init(identifier: Int, imageSource: KHImageSource, cropRect: KHCropRect? = nil, orientation: KHOrientation2? = nil, desqueeze: Double? = nil)
    {
        self.identifier = identifier
        self.cropRect = cropRect
        self.orientation = orientation
        self.desqueeze = desqueeze
        
        super.init(frame: .standard)
        
        self._configure()
        self._populate(with: imageSource)
    }
    
    // MARK: - Public
    
    var selected: Bool = false
    
    var cropViewMode: KHCroppedView.ViewMode
    {
        get {
            self._croppedView?.mode ?? .viewer
        }
        set {
            self._croppedView?.mode = newValue
        }
    }
    
    var identifier: Int
    var orientation: KHOrientation2?
    {
        didSet {
            guard self.orientation != oldValue else {
                return
            }
            
            if  let orientation = self.orientation {
                self._updateOrientedView(with: orientation)
            } else {
                self._removeOrientedView(with: oldValue)
            }
            
            self.setNeedsLayout()
        }
    }
    var cropRect: KHCropRect?
    {
        didSet {
            self._croppedView?.cropRect = self.cropRect
        }
    }
    
    var desqueeze: Double?
    {
        didSet {
            guard self.desqueeze != oldValue else {
                return
            }
            
            self._imageView?.desqueeze = self.desqueeze != nil ? CGFloat(self.desqueeze!) : nil
        }
    }
        
    func updateColors()
    {
        self._updateCroppedViewColors()
    }
    
    func assignEditorView(from photoView: KHPhotoView)
    {
        guard let editorView = photoView.removeEditorView() else {
            return
        }
        self.assignEditorView(editorView)
    }
        
    func assignEditorView(_ editorView: UIView)
    {
        guard self._editorView !== editorView else {
            return
        }
        self._editorView = editorView
        
        guard let orientedView = self._orientedView else {
            
            editorView.frame = self.bounds
            self.addSubview(editorView)
            editorView.layoutIfNeeded()
            
            return
        }
        
        orientedView.assignEditorView(editorView)
    }
    
    @discardableResult
    func removeEditorView() -> UIView?
    {
        guard let editorView = self._editorView else {
            return nil
        }
        self._editorView = nil
        
        guard let orientedView = self._orientedView else {
        
            if  editorView.superview === self {
                editorView.removeFromSuperview()
            }
            return editorView
        }
        
        return orientedView.removeEditorView()
    }
    
    func updateEditorView(in block: (_ editorView: UIView) -> Void)
    {
        guard let editorView = self._editorView else {
            return
        }
        block(editorView)
    }
            
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        if  let view = self._topmostContentView {
            view.frame = self.bounds
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    // MARK: - Private
    
    private var _editorView: UIView?
    
    private weak var _orientedView: KHOrientedView?
    private weak var _croppedView: KHCroppedView?
    private weak var _imageView: KHImageView?
    
    private var _topmostContentView: UIView? {
        return self._orientedView ?? self._croppedView ?? self._imageView
    }
    
    private func _configure()
    {
        self.clipsToBounds = false
    }
    
    private func _createImageView(with imageSource: KHImageSource) -> KHImageView
    {
        let view = KHImageView(with: imageSource, displayMode: .ratioFill)
        
        self._imageView = view
        return view
    }
    
    private func _createCroppedView(with cropRect: KHCropRect?, contentView: UIView?) -> KHCroppedView
    {
        let view = KHCroppedView(contentView: contentView, config: .init(contentBorderWidth: KHPixel))
        view.cropRect = cropRect
        
        self._croppedView = view
        self._updateCroppedViewColors()
        return view
    }
    
    private func _createOrientedView(with orientation: KHOrientation2, contentView: UIView?) -> KHOrientedView
    {
        let view = KHOrientedView(contentView: contentView)
        view.orientation = orientation
        
        self._orientedView = view
        return view
    }
    
    private func _populate(with imageSource: KHImageSource)
    {
        // cropped view is always visible
        
        let imageView = self._createImageView(with: imageSource)
        var contentView: UIView = self._createCroppedView(with: self.cropRect, contentView: imageView)
        
        if  let orientation = self.orientation {
            contentView = self._createOrientedView(with: orientation, contentView: contentView)
        }
        if  let desqueeze = self.desqueeze {
            imageView.desqueeze = desqueeze
        }
        
        self.addSubview(contentView)
    }
    
    private func _updateOrientedView(with orientation: KHOrientation2)
    {
        if  let view = self._orientedView {
            view.orientation = orientation
            return
        }
        
        let view = self._createOrientedView(with: orientation, contentView: self._croppedView ?? self._imageView)
        if  let editorView = self._editorView {
            view.assignEditorView(editorView)
        }
        
        self.insertSubview(view, at: 0)
    }
    
    private func _resetOrientaion(_ orientation: KHOrientation2?, frame: CGRect, for views: [UIView?])
    {
        guard UIView.inheritedAnimationDuration > 0, let transform = orientation?.transform else {
            views.forEach { $0?.frame = frame }
            return
        }
        
        for view in views {
            guard let view = view else {
                continue
            }
            
            UIView.performWithoutAnimation {
                view.transform = transform
                view.frame = frame
            }
            view.transform = .identity
            view.frame = frame
        }
    }
    
    private func _removeOrientedView(with orientation: KHOrientation2?)
    {
        guard let view = self._orientedView else {
            return
        }
        self._orientedView = nil
        
        if  let contentView = view.contentView {
            self.insertSubview(contentView, at: 0)
        }
        if  let editorView = view.removeEditorView() {
            self.addSubview(editorView)
            self._editorView = editorView
        }
        
        self._resetOrientaion(orientation, frame: self.bounds, for: [view.contentView, self._editorView])
        
        view.removeFromSuperview()
    }
    
    private func _updateCroppedViewColors()
    {
        self._croppedView?.contentBorderColor = KHTheme.color.cropContentBorder
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

