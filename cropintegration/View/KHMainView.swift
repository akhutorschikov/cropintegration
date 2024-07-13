//
//  KHMainViewContentProvider.swift
//  cropintegration
//
//  Created by Alex Khuala on 29.03.24.
//

import UIKit

protocol KHMainView_Delegate: AnyObject
{
    func mainViewDidRequestEditPhoto(_ view: KHEditViewModel_Delegate)
}

class KHMainViewContentProvider: KHZoomScrollView_ContentProvider
{
    init(with viewModel: KHMainView_ViewModel, delegate: KHMainView_Delegate?)
    {
        self._viewModel = viewModel
        self._delegate = delegate
    }
    
    func createContentView() -> KHView
    {
        KHInternalView(with: self._viewModel, delegate: self._delegate)
    }
    
    var contentSize: CGSize {
        self._viewModel.contentSize
    }
    
    let minimumZoom: KHZoom.InitialZoom = .fitContainer(inset: .init(22), aspect: .bounds)
    
    // MARK: - Private
    
    private let _viewModel: KHMainView_ViewModel
    private weak var _delegate: KHMainView_Delegate?
}



// *************************
// *************************   VIEW
// *************************


fileprivate class KHInternalView: KHView, KHColor_Sensitive
{
    // MARK: - Init
    
    init(with viewModel: KHMainView_ViewModel, delegate: KHMainView_Delegate?, config: Config = .init())
    {
        self._config = config
        self._delegate = delegate
        self._viewModel = viewModel
        super.init(frame: .standard)
        self._configure()
        self._populate()
        
        viewModel.listeners.add(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self._viewModel.listeners.remove(self)
    }
    
    // MARK: - Public
    
    func updateColors()
    {
        self.backgroundColor = KHTheme.color.canvas
        self._listView?.updateColors()
    }
    
    struct Config: KHConfig_Protocol
    {
        //
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        if  let view = self._photoView {
            view.frame = self._viewModel.imageFrame
        }
        
        if  let view = self._listView {
            view.frame = self._viewModel.listFrame
            view.forceLayout(options: .sizeToFitHeight)
        }
    }
    
    // MARK: - Private
    
    private let _config: Config
    private let _viewModel: KHMainView_ViewModel
    private weak var _delegate: KHMainView_Delegate?
    
    private weak var _photoView: UIView?
    private weak var _listView: KHListView<KHMainListContentProvider>?
    
    private func _configure()
    {
        self.clipsToBounds = true
    }
    
    private func _populate()
    {
        let view = self._addPhotoView(cropRect: self._viewModel.cropRect, orientation: self._viewModel.orientation)
        self._photoView = view
        
        self._addListView()
                
        // ------ Add double tap gesture recognizer
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(_didDoubleTap(_:)))
        gr.numberOfTapsRequired = 2
        
        view.addGestureRecognizer(gr)
    }
    
    private func _addPhotoView(cropRect: KHCropRect?, orientation: KHOrientation2?, highResolution: Bool = false) -> KHPhotoView
    {
        let view = KHPhotoView(identifier: 0, imageSource: highResolution ? self._viewModel.highResImageSource : self._viewModel.imageSource, cropRect: cropRect, orientation: orientation)
        
        self.addSubview(view)
        return view
    }
    
    private func _addListView()
    {
        let view = KHListView(with: KHMainListContentProvider())
        view.isUserInteractionEnabled = false
        
        self.addSubview(view)
        self._listView = view
    }
    
    // MARK: - Actions
    
    @objc
    private func _didDoubleTap(_ gr: UIGestureRecognizer)
    {
        switch gr.state {
        case .ended:
            
            self._delegate?.mainViewDidRequestEditPhoto(self)
            
        default:
            break
        }
    }
}

extension KHInternalView: KHEditViewModel_Delegate 
{
    func maskViewFrame(in view: UIView?) -> CGRect?
    {
        guard let superview = self.superview else {
            return nil
        }
        return superview.convert(superview.bounds, to: view)
    }
    
    func willBeginCapturingView(with identifier: Int?) -> KHEditContentViewSource?
    {
        guard let displayView = self._photoView as? KHPhotoView else {
            return nil
        }
        
        let placeholder = UIView()
        placeholder.isHidden = true
        placeholder.frame = displayView.frame
        
        self.insertSubview(placeholder, belowSubview: displayView)
        self._photoView = placeholder
                
        let editingView = self._addPhotoView(cropRect: displayView.cropRect, orientation: displayView.orientation, highResolution: true)
                
        return .init(displayView: displayView, editingView: editingView, placeholder: placeholder)
    }
        
    func didFinishReleasingView(with source: KHEditContentViewSource)
    {
        source.placeholder.removeFromSuperview()
        self._photoView = source.displayView
    }
}

extension KHInternalView: KHMainView_Listener
{
    func didRequestCrop() 
    {
        self._delegate?.mainViewDidRequestEditPhoto(self)
    }
}
