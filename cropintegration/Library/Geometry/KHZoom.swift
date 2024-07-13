//
//  KHZoom.swift
//  cropintegration
//
//  Created by Alex Khuala on 29.03.24.
//

import UIKit

class KHZoom
{
    enum InitialZoom
    {
        case scale(CGFloat)
        case fitContainer(inset: KHInset = .zero, aspect: Zoom.Aspect = .bounds)
        
        enum Option
        {
            case minimum
            case maximum
            case custom(InitialZoom)
        }
        
        var zoom: Zoom {
            switch self {
            case let .scale(v):
                .scale(v)
            case let .fitContainer(a, b):
                .fitContainer(inset: a, aspect: b)
            }
        }
    }
    
    struct InitialSnap
    {
        init(_ zoomOption: InitialZoom.Option, align: ContentAlign = .auto)
        {
            self.zoomOption = zoomOption
            self.align = align
        }
        
        let zoomOption: InitialZoom.Option
        let align: ContentAlign
    }
    
    enum Zoom
    {
        case relative(Int)
        case scale(CGFloat)
        case fitContainer(inset: KHInset = .zero, aspect: Aspect = .bounds)
        
        enum Aspect
        {
            case width
            case height
            case bounds
        }
        
        enum Option
        {
            case initial
            case minimum
            case maximum
            case custom(Zoom)
        }
        
        func contentScale(contentSize: CGSize, containerSize: CGSize, initialScale: CGFloat = 1) -> CGFloat
        {
            switch self {
            case let .relative(value):
                return initialScale * CGFloat(value) / 100
                
            case let .scale(scale):
                return scale > 0 ? scale : 1
                
            case let .fitContainer(inset, aspect):
                
                switch aspect {
                case .width:
                    
                    let width = containerSize.width - inset.left - inset.right
                    guard contentSize.width > 0, width > 0 else {
                        return 1
                    }
                    return width / contentSize.width
                    
                case .height:
                    
                    let height = containerSize.height - inset.top - inset.bottom
                    guard contentSize.height > 0, height > 0 else {
                        return 1
                    }
                    return height / contentSize.height
                    
                case .bounds:
                    
                    let bounds = containerSize.inset(inset)
                    guard contentSize.width > 0, contentSize.height > 0, bounds.width > 0, bounds.height > 0 else {
                        return 1
                    }
                    let innerBounds = bounds.ratio(contentSize.ratio, true)
                    return innerBounds.width / contentSize.width
                }
            }
        }
        
        static let standard: Self = .scale(1)
    }
    
    struct ContentAlign: KHAxisGeometry_Editable
    {
        static let zero: Self = .init()
        
        var componentHorizontal: Component {
            get { self.x }
            set { self.x = newValue }
        }
        
        var componentVertical: Component {
            get { self.y }
            set { self.y = newValue }
        }
        
        init(_ x: Component, _ y: Component)
        {
            self.x = x
            self.y = y
        }
        init(_ xy: Component = .auto)
        {
            self.init(xy, xy)
        }
        init(x: Component = .auto, y: Component = .auto)
        {
            self.init(x, y)
        }
        
        var x: Component
        var y: Component
        
        enum Component
        {
            case start
            case end
            case center
            case auto
            
            func update(with align: Component, force: Bool) -> Self
            {
                force || align != .auto ? align : self
//                align == .auto ? self : align
            }
        }
        
        static let auto: Self = .init()
    }
    
    struct ZoomSnap
    {
        init(zoomOption: Zoom.Option, align: ContentAlign = .auto)
        {
            self.zoomOption = zoomOption
            self.align = align
        }
        
        mutating func reset(align: ContentAlign)
        {
            self.align = align
            self.forceAlign = true
        }
        
        private(set) var align: ContentAlign
        private(set) var forceAlign: Bool = false
        let zoomOption: Zoom.Option
    }
    
    struct ZoomState
    {
        init(_ scale: CGFloat, _ align: ContentAlign = .auto)
        {
            self.scale = scale
            self.align = align
        }
        
        func update(with align: ContentAlign, force: Bool) -> Self
        {
            return .init(self.scale, .init(self.align.x.update(with: align.x, force: force), self.align.y.update(with: align.y, force: force)))
        }
        
        let scale: CGFloat
        let align: ContentAlign
        
        static let standard: Self = .init(1)
    }
}
