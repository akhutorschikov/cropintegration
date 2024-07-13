//
//  KHImageView.swift
//  cropintegration
//
//  Created by Alex Khuala on 27.12.22.
//

import UIKit

class KHImageSource
{
    // overridable
    public func image(size: CGSize? = nil) -> UIImage?
    {
        return nil
    }
    
    final public func setNeedsReload()
    {
        self.parent?.reloadImage()
    }
    
    static public func name(_ name: String) -> KHImageSource
    {
        KHImageBundleSource(name)
    }
    static public func url(_ url: URL, alternativeSource: KHImageSource? = nil) -> KHImageSource
    {
        KHImageURLSource(url, alternativeSource: alternativeSource)
    }
    
    static public func empty() -> KHImageSource
    {
        KHImageEmptySource()
    }
    
    fileprivate weak var parent: KHImageView?
}



// TODO: Need extra 'resolution' parameter to propertly render tile image



class KHImageView: KHView
{
    // MARK: - Init
    
    init(with source: KHImageSource, pixelSize: CGSize? = nil, displayMode: DisplayMode = .center, padding: UIEdgeInsets = .zero, align: KHAlign = .center)
    {
        self.source = source
        self.align = align
        self.padding = padding
        self.displayMode = displayMode
        self.pixelSize = pixelSize
        
        super.init(frame: .standard)
        
        self._configure()
        self.source.parent = self
        self._addImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    var source: KHImageSource
    {
        didSet {
            self.source.parent = self
            self.reloadImage()
        }
    }
    
    var align: KHAlign
    {
        didSet {
            guard self.align != oldValue else {
                return
            }
            self.setNeedsLayout()
        }
    }
    
    var padding: UIEdgeInsets
    {
        didSet {
            guard self.padding != oldValue else {
                return
            }
            self.setNeedsLayout()
        }
    }
    
    var displayMode: DisplayMode
    {
        didSet {
            guard self.displayMode != oldValue else {
                return
            }
            if  self.displayMode == .tile || oldValue == .tile {
                self._imageView?.image = self._image
            }
            
            self.setNeedsLayout()
        }
    }
    
    var pixelSize: CGSize?
    {
        didSet {
            guard self.pixelSize != oldValue else {
                return
            }
            self.reloadImage()
        }
    }
    
    enum DisplayMode
    {
        case center
        case stretch
        case ratioFit
        case ratioFill
        case tile
    }
    
    fileprivate func reloadImage()
    {
        self._imageView?.image = self._image
        self.setNeedsLayout()
    }
    
    public var imageSize: CGSize
    {
        guard let size = self._imageView?.image?.size else {
            return .zero
        }
        return size.desqueeze(self.desqueeze, accuracy: 0.0001)
    }
        
    public var minSize: CGSize
    {
        self.imageSize.inset(self.padding.scale(-1))
    }
    
    public var desqueeze: CGFloat?
    {
        didSet {
            guard self.desqueeze != oldValue else {
                return
            }
            self.setNeedsLayout()
        }
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: LayoutOptions)
    {
        guard let view = self._imageView else {
            return
        }
        
        let bounds = self.bounds.inset(contentInset.expand(to: self.padding))
        let imageSize = self.imageSize
        
        let size: CGSize
        switch self.displayMode {
        case .ratioFill:
            size = bounds.size.ratio(imageSize.ratio, false)
        case .ratioFit:
            size = bounds.size.ratio(imageSize.ratio, true)
        case .stretch, .tile:
            size = .zero
        case .center:
            size = imageSize
        }
        
        view.frame = bounds.inframe(size, self.align).pixelRound()
    }
    
    // MARK: - Private
    
    private weak var _imageView: UIImageView?
    
    private var _image: UIImage?
    {
        guard let image = self.source.image(size: self.pixelSize) else {
            return nil
        }
        
        switch self.displayMode {
        case .tile:
            return image.resizableImage(withCapInsets: .zero, resizingMode: .tile)
        default:
            return image
        }
    }
    
    private func _configure()
    {
        self.clipsToBounds = true
    }
    
    private func _addImageView()
    {
        let imageView = UIImageView(image: self._image)
        
        self.addSubview(imageView)
        self._imageView = imageView
    }
}



// *************************
// *************************
// *************************

fileprivate class KHImageEmptySource: KHImageSource
{
    override func image(size: CGSize? = nil) -> UIImage?
    {
        return nil
    }
}

fileprivate class KHImageBundleSource: KHImageSource
{
    init(_ name: String)
    {
        self._name = name
    }
    
    override func image(size: CGSize? = nil) -> UIImage?
    {
        return UIImage(named: self._name)
    }
    
    // MARK: - Private
    
    private var _name: String
}

fileprivate class KHImageURLSource: KHImageSource
{
    let url: URL
    
    init(_ url: URL, alternativeSource: KHImageSource? = nil)
    {
        self.url = url
        self._alternativeSource = alternativeSource
    }
    
    override func image(size: CGSize? = nil) -> UIImage?
    {
        guard let data = try? Data(contentsOf: self.url), let image = UIImage(data: data) else {
            return self._alternativeSource?.image(size: size)
        }
        
        let width = image.size.width
        guard let size = size, width > 0, abs(size.width - width) > 0.01, let cgImage = image.cgImage else {
            return image
        }
        
        let scale = width / size.width
        return .init(cgImage: cgImage, scale: scale * image.scale, orientation: image.imageOrientation)
    }
    
    private let _alternativeSource: KHImageSource?
}
