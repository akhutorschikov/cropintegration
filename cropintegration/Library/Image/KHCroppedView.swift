//
//  KHCroppedView.swift
//  cropintegration
//
//  Created by Alex Khuala on 28.08.23.
//

import UIKit

final class KHCroppedView: UIView
{
    // MARK: - Init
    
    init(contentView: UIView?, config: Config = .init())
    {
        self._config = config
        
        super.init(frame: .standard)
        
        self._configure()
        self._addContentView(contentView)
        
        self._addTestView()
    }
    
    // MARK: - Public
    
    var contentBorderColor: UIColor?
    {
        didSet {
            if  let view = self._contentView {
                self._updateContentViewBorder(view)
            }
        }
    }
    
    private weak var _contentView: UIView?
    
    func assignContentView(_ contentView: UIView?)
    {
        guard contentView !== self._contentView else {
            return
        }
        
        if  let view = self._contentView, view.superview === self {
            view.removeFromSuperview()
        }
        
        self._addContentView(contentView)
    }
    
    func withdrawContentView() -> UIView?
    {
        guard let view = self._contentView else {
            return nil
        }
        
        if  view.superview === self {
            view.removeFromSuperview()
        }
        
        view.transform = .identity
        view.layer.anchorPoint = .init(0.5)
        
        self._contentView = nil
        return view
    }
    
    var mode: ViewMode = .viewer
    {
        didSet {
            guard self.mode != oldValue else {
                return
            }
            
            switch self.mode {
            case .editor(let maskAlpha):
                self._activateMaskView(maskAlpha)
            case .viewer:
                self._deactivateMaskView()
            }
            
            if  let view = self._contentView {
                self._updateContentViewBorder(view)
            }
        }
    }
    
    public var cropRect: KHCropRect?
    {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override var frame: CGRect
    {
        set {
            super.frame = newValue
            self.mask?.frame = self.bounds
        }
        get {
            return super.frame
        }
    }
    
    struct Config: KHConfig_Protocol
    {
        var contentBorderWidth: CGFloat = 0
    }
    
    enum ViewMode: Equatable
    {
        case viewer
        case editor(_ maskAlpha: CGFloat)
    }
    
    // MARK: - Layout

    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        if  self._size != self.size || self._needs {
            self._size  = self.size
            self._needs = false
            self._layout()
        }
    }
    
    override func setNeedsLayout() 
    {
        self._needs = true
        super.setNeedsLayout()
    }
    
    // MARK: - Private
    
    private var _size: CGSize?
    private var _needs = true
    
    private let _config: Config
    
    private func _configure()
    {
        self._deactivateMaskView()
    }
    
    private func _addContentView(_ view: UIView?)
    {
        guard let view = view else {
            return
        }
        
        self.addSubview(view)
        self._contentView = view
        
        self._updateContentViewBorder(view)
        self.setNeedsLayout()
    }
    
    private weak var _testView: UIView?
    
    private func _addTestView()
    {
        let view = UIView()
        view.backgroundColor = .red
        
        self.addSubview(view)
        self._testView = view
    }
    
    private func _updateContentViewBorder(_ contentView: UIView)
    {
        if  self._config.contentBorderWidth > 0, self.mode != .viewer {
            contentView.layer.borderWidth = self._config.contentBorderWidth
            contentView.layer.borderColor = self.contentBorderColor?.cgColor
        } else {
            contentView.layer.borderWidth = 0
            contentView.layer.borderColor = nil
        }
    }
    
    private func _activateMaskView(_ alpha: CGFloat)
    {
        if  let mask = self.mask {
            mask.alpha = alpha
        } else {
            self.mask = KHCropMask(self.bounds, alpha)
            self.clipsToBounds = false
        }
    }
    
    private func _deactivateMaskView()
    {
        self.mask = nil
        self.clipsToBounds = true
    }
    
    private func _layout()
    {
        guard let view = self._contentView else {
            return
        }
        
        if  var cropRect = self.cropRect, cropRect.isSafeAsDevider() {
            
            let imageSize = cropRect.maxSize
            
            let sizeRatio = self.bounds.size.ratio
            let cropRatio = cropRect.frame.size.ratio
            
            if  abs(sizeRatio - cropRatio) < 0.01 {
                let editor = KHCropRect.Editor(with: cropRect, minSize: 1)
                editor.fill(outerRatio: sizeRatio)
                cropRect = editor.cropRect
            }
            
            let cropFrame = cropRect.frame
            
            let sx = self.bounds.width  / cropFrame.width
            let sy = self.bounds.height / cropFrame.height

            var anchorPoint = cropFrame.center
            anchorPoint.x /= imageSize.width
            anchorPoint.y /= imageSize.height

            view.bounds = imageSize.scale(sx, sy).bounds
            view.layer.anchorPoint = anchorPoint
            view.layer.position = self.bounds.center
            view.transform = CGAffineTransform(rotationAngle: cropRect.angle)
            
        } else {
            
            view.transform = .identity
            view.layer.anchorPoint = .init(0.5)
            view.frame = self.bounds
        }
        
        view.layoutIfNeeded()
    }
    
    // MARK: - System
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
