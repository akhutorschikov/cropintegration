//
//  KHZoomScrollView.swift
//  cropintegration
//
//  Created by Alex Khuala on 29.03.24.
//

import UIKit

protocol KHZoomScrollView_ContentProvider
{
    func createContentView() -> KHView
    
    var contentSize: CGSize { get }
    
    var minimumZoom: KHZoom.InitialZoom { get }
    var maximumZoom: KHZoom.InitialZoom { get } // optional, default .scale(1)
    var initialSnap: KHZoom.InitialSnap { get } // optional, default .minimum
}

extension KHZoomScrollView_ContentProvider
{
    var maximumZoom: KHZoom.InitialZoom { .scale(1) } // optional, default .standard
    var initialSnap: KHZoom.InitialSnap { .init(.minimum) } // optional, default .minimum
}

// *************************
// *************************
// *************************

class KHZoomScrollView: KHView, KHColor_Sensitive
{
    // MARK: - Init
    
    init(with contentProvider: KHZoomScrollView_ContentProvider, config: Config = .init())
    {
        self._config = config
        self._contentProvider = contentProvider
        super.init(frame: .standard)
        self._configure()
        self._populate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    func updateColors()
    {
        KHColorSensitiveTools.updateColors(of: self._contentView)
    }
    
    struct Config: KHConfig_Protocol
    {
        var alwaysBounce: Bool = true
        var showsScrollIndicators: Bool = true
        var animationDuration: TimeInterval = 0.25
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        guard let scrollView = self._scrollView, let view = self._contentView else {
            return
        }
        
        let bounds = self.bounds
        
        // ------

        let contentSize = self._contentProvider.contentSize
        view.bounds = contentSize.bounds
        view.origin = .zero
        
        scrollView.frame = bounds
        
        // ------ min zoom scale
        
        let minScale = self._contentProvider.minimumZoom.zoom.contentScale(contentSize: contentSize, containerSize: bounds.size)
        
        if  scrollView.minimumZoomScale != minScale {
            scrollView.minimumZoomScale  = minScale
        }
        
        // ------ fix zoom scale and content size
                
        if  scrollView.zoomScale < minScale {
            scrollView.zoomScale = minScale
        }
        
        scrollView.contentSize = contentSize.scale(scrollView.zoomScale)
        
        // ------ max zoom scale
        
        let maxScale = self._contentProvider.maximumZoom.zoom.contentScale(contentSize: contentSize, containerSize: bounds.size)
        
        if  scrollView.maximumZoomScale != maxScale {
            scrollView.maximumZoomScale  = maxScale
        }
        
        // ------ update initial state
        
        let initialSnap = self._contentProvider.initialSnap
        let initialScale: CGFloat
        switch initialSnap.zoomOption {
        case .minimum:
            initialScale = minScale
        case .maximum:
            initialScale = maxScale
        case .custom(let initialZoom):
            initialScale = initialZoom.zoom.contentScale(contentSize: contentSize, containerSize: bounds.size)
        }
        
        self._initialZoomState = .init(initialScale, initialSnap.align)
        
        if !self._zoomInitialized {
            self._zoomInitialized = true
            
            if  self._zoomSnap == nil {
                self._zoomSnap = .init(zoomOption: .initial, align: initialSnap.align)
            }
        }
        
        // ------ current zoom scale
        
        self._applyZoomSnap(self._zoomSnap, zoomView: view, scrollView: scrollView, animated: false)
    }
    
    // MARK: - Private
    
    private let _config: Config
    private let _contentProvider: KHZoomScrollView_ContentProvider
    
    private weak var _scrollView: UIScrollView?
    private weak var _contentView: KHView?
    
    private var _zoomInitialized: Bool = false
    private var _initialZoomState: KHZoom.ZoomState = .standard
    private var _zoomSnap: KHZoom.ZoomSnap?
    
    private func _configure()
    {
        self.clipsToBounds = true
    }
    
    private func _populate()
    {
        self._addScrollView()
        self._addContentView()
    }
    
    private func _addScrollView()
    {
        let view = UIScrollView(.standard)
        
        // configure scroll view
        view.contentInsetAdjustmentBehavior = .never
        view.decelerationRate = .fast
        view.scrollsToTop = false
        view.delegate = self
        view.delaysContentTouches = false
        
        let shows = self._config.showsScrollIndicators
        view.showsVerticalScrollIndicator = shows
        view.showsHorizontalScrollIndicator = shows
        
        let bounce = self._config.alwaysBounce
        view.alwaysBounceVertical = bounce
        view.alwaysBounceHorizontal = bounce
        
        self.addSubview(view)
        self._scrollView = view
    }
    
    private func _addContentView()
    {
        let view = self._contentProvider.createContentView()
        
        self._scrollView?.addSubview(view)
        self._contentView = view
    }
    
    private func _updateContentInset(for scrollView: UIScrollView)
    {
        let contentSize = scrollView.contentSize
        let scrollSize = scrollView.size
                
        var contentInset: UIEdgeInsets = .zero
        
        let extraWidth = scrollSize.width - contentSize.width
        if  extraWidth > 0 {
            contentInset.x = extraWidth / 2
        }
        let extraHeight = scrollSize.height - contentSize.height
        if  extraHeight > 0 {
            contentInset.y = extraHeight / 2
        }
        
        scrollView.contentInset = contentInset
    }
    
    // MARK: - Zoom
    
    private func _applyZoomSnap(_ zoomSnap: KHZoom.ZoomSnap?, zoomView: UIView, scrollView: UIScrollView, animated: Bool)
    {
        let zoomState: KHZoom.ZoomState
        if  let zoomSnap = zoomSnap {
            switch zoomSnap.zoomOption {
            case .maximum:
                zoomState = .init(scrollView.maximumZoomScale, zoomSnap.align)
            case .minimum:
                zoomState = .init(scrollView.minimumZoomScale, zoomSnap.align)
            case .initial:
                zoomState = self._initialZoomState.update(with: zoomSnap.align, force: zoomSnap.forceAlign)
            case let .custom(zoom):
                zoomState = .init(zoom.contentScale(contentSize: zoomView.bounds.size, containerSize: scrollView.frame.size, initialScale: self._initialZoomState.scale), zoomSnap.align)
            }
        } else {
            zoomState = .init(scrollView.zoomScale)
        }
        
        self._updateZoomState(zoomState, for: scrollView, animated: animated)
    }
    
    private func _updateZoomState(_ state: KHZoom.ZoomState, for scrollView: UIScrollView, animated: Bool = false)
    {
        let changeBlock = { [weak self] in
            guard let self = self, let scrollView = self._scrollView else {
                return
            }
            
            // ------- update zoom scale
            
            if  scrollView.zoomScale != state.scale {
                scrollView.zoomScale  = state.scale
            }
            
            // ------- update content inset
            
            self._updateContentInset(for: scrollView)
        }
        
        guard animated else {
            changeBlock()
            return
        }
        
        UIView.animate(withDuration: self._config.animationDuration, animations: changeBlock)
    }
}


extension KHZoomScrollView: UIScrollViewDelegate
{
    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
        self._contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) 
    {
        if  scrollView.isZooming {
            self._zoomSnap = nil
        }
        
        self._updateContentInset(for: scrollView)
    }
}
