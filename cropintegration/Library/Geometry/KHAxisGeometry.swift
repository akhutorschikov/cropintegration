//
//  KHAxisGeometry.swift
//  cropintegration
//
//  Created by Alex Khuala on 14.08.23.
//

import UIKit

final class KHAxisGeometry // Components
{
    private init(){}
    
    static func enumerate(in block: (_ axis: Axis, _ horizontal: Bool, _ geometry: Geometry, _ stop: inout Bool) -> Void)
    {
        var stop: Bool = false
        block(Axis.horizontal, true, Axis.horizontal.geometry, &stop)
        if !stop {
            block(Axis.vertical, false, Axis.vertical.geometry, &stop)
        }
    }
    
    static func perform(_ horizontal: Bool, in block: (_ axis: Axis, _ horizontal: Bool, _ geometry: Geometry) -> Void)
    {
        (horizontal ? Axis.horizontal : Axis.vertical).perform(in: block)
    }
    
    typealias Geometry = KHAxisGeometry_Geometry.Type
    
    struct Axis: CaseIterable, Hashable
    {
        typealias Geometry = KHAxisGeometry_Geometry.Type
        
        let geometry: Geometry
        
        // MARK: - Static
        
        static let horizontal: Self = .init(.horizontal)
        static let vertical  : Self = .init(.vertical)
        
        static let allCases: [Self] = [.horizontal, .vertical]
        
        func perform(in block: (_ axis: Axis, _ horizontal: Bool, _ geometry: Geometry) -> Void)
        {
            block(self, self == .horizontal, self.geometry)
        }
        
        // MARK: - Private
        
        static func == (a: Self, b: Self) -> Bool
        {
            a._internalType == b._internalType
        }
        func hash(into hasher: inout Hasher)
        {
            hasher.combine(self._internalType)
        }
        
        private enum InternalType
        {
            case horizontal
            case vertical
        }
        
        private init(_ internalType: InternalType)
        {
            self._internalType = internalType
            switch internalType {
            case .horizontal:
                self.geometry = HorizontalGeometry.self
            case .vertical:
                self.geometry = VerticalGeometry.self
            }
        }
        
        private let _internalType: InternalType
    }
        
    struct Components<Item: KHAxisGeometry_Editable>
    {
        var main: Item.Component
        var next: Item.Component
        
        init(_ main: Item.Component, _ next: Item.Component)
        {
            self.main = main
            self.next = next
        }
        
        func rotate(_ condition: Bool = true) -> Self
        {
            guard condition else {
                return self
            }
            return .init(self.next, self.main)
        }
    }
    
    struct Collection<T>
    {
        func forEach(_ block: (T) -> Void)
        {
            block(self._elements[0])
            block(self._elements[1])
        }
        
        func enumerate(in block: (_ axis: Axis, T, _ horizontal: Bool, _ geometry: Geometry, _ stop: inout Bool) -> Void)
        {
            var stop: Bool = false
            block(Axis.horizontal, self._elements[0], true, Axis.horizontal.geometry, &stop)
            if !stop {
                block(Axis.vertical, self._elements[1], false, Axis.vertical.geometry, &stop)
            }
        }
        
        func convert<T2>(in block: (_ main: T, _ next: T) -> T2) -> Collection<T2>
        {
            .init(block(self._elements[0], self._elements[1]), block(self._elements[1], self._elements[0]))
        }
        
        func extract(for axis: Axis) -> (Axis, T, Bool, Geometry)
        {
            (axis, self[axis], axis == .horizontal, axis.geometry)
        }
        
        func extract(for axis: Axis, in block: (_ axis: Axis, T, _ horizontal: Bool, _ geometry: Geometry) -> Void)
        {
            block(axis, self[axis], axis == .horizontal, axis.geometry)
        }
        
        func update(for axis: Axis, in block: (T) -> Void)
        {
            block(self[axis])
        }
        
        subscript(axis: Axis) -> T
        {
            self._elements[axis == .horizontal ? 0 : 1]
        }
        
        init(_ horizontal: T, _ vertical: T)
        {
            self._elements = [horizontal, vertical]
        }
        
        private let _elements: [T]
    }
}


// *************************
// *************************
// *************************

protocol KHAxisGeometry_Editable
{
    associatedtype Component
    
    static var zero: Self { get }
    func component(_ geometry: KHAxisGeometry.Geometry) -> Component
    func components(_ geometry: KHAxisGeometry.Geometry) -> KHAxisGeometry.Components<Self>
    var componentHorizontal: Component { get set }
    var componentVertical: Component { get set }
}

extension KHAxisGeometry_Editable
{
    func component(_ geometry: KHAxisGeometry.Geometry) -> Component
    {
        geometry.component(of: self)
    }
    func components(_ geometry: KHAxisGeometry.Geometry) -> KHAxisGeometry.Components<Self>
    {
        geometry.components(of: self)
    }
}

protocol KHAxisGeometry_Geometry
{
    static var next: KHAxisGeometry_Geometry.Type { get }
    
    static func components<Item>(of item: Item) -> KHAxisGeometry.Components<Item> where Item: KHAxisGeometry_Editable
    static func component<Item>(of item: Item) -> Item.Component where Item: KHAxisGeometry_Editable
    static func update<Item>(_ item: inout Item, with component: Item.Component) where Item: KHAxisGeometry_Editable
    static func update<Item>(_ item: inout Item, in block: (_ component: inout Item.Component) -> Void) where Item: KHAxisGeometry_Editable
    static func restore<Item>(from components: KHAxisGeometry.Components<Item>) -> Item where Item: KHAxisGeometry_Editable
    static func orient<Item>(_ item: Item) -> Item where Item: KHAxisGeometry_Editable
}

extension KHAxisGeometry_Geometry
{
    static func components<Item>(of item: Item) -> KHAxisGeometry.Components<Item> where Item: KHAxisGeometry_Editable
    {
        .init(self.component(of: item), next.component(of: item))
    }
    static func restore<Item>(from components: KHAxisGeometry.Components<Item>) -> Item where Item: KHAxisGeometry_Editable
    {
        var item: Item = .zero
        
        self.update(&item, with: components.main)
        next.update(&item, with: components.next)
        
        return item
    }
}


extension KHAxisGeometry {
    
    final class HorizontalGeometry: KHAxisGeometry_Geometry
    {
        static var next: KHAxisGeometry_Geometry.Type
        {
            return KHAxisGeometry.VerticalGeometry.self
        }
        
        static func component<Item>(of item: Item) -> Item.Component where Item: KHAxisGeometry_Editable
        {
            item.componentHorizontal
        }
        static func update<Item>(_ item: inout Item, with component: Item.Component) where Item: KHAxisGeometry_Editable
        {
            item.componentHorizontal = component
        }
        static func update<Item>(_ item: inout Item, in block: (_ component: inout Item.Component) -> Void) where Item: KHAxisGeometry_Editable
        {
            block(&item.componentHorizontal)
        }
        
        static func orient<Item>(_ item: Item) -> Item where Item : KHAxisGeometry_Editable
        {
            return item
        }
    }
}

extension KHAxisGeometry {
    
    final class VerticalGeometry: KHAxisGeometry_Geometry
    {
        static var next: KHAxisGeometry_Geometry.Type
        {
            return KHAxisGeometry.HorizontalGeometry.self
        }
        
        static func component<Item>(of item: Item) -> Item.Component where Item: KHAxisGeometry_Editable
        {
            item.componentVertical
        }
        static func update<Item>(_ item: inout Item, with component: Item.Component) where Item: KHAxisGeometry_Editable
        {
            item.componentVertical = component
        }
        static func update<Item>(_ item: inout Item, in block: (_ component: inout Item.Component) -> Void) where Item: KHAxisGeometry_Editable
        {
            block(&item.componentVertical)
        }
        static func orient<Item>(_ item: Item) -> Item where Item : KHAxisGeometry_Editable
        {
            self.restore(from: .init(item.componentHorizontal, item.componentVertical))
        }
    }
}


// *************************
// *************************
// *************************


extension CGPoint: KHAxisGeometry_Editable
{
    typealias Component = CGFloat
    
    var componentHorizontal: Component {
        get { self.x }
        set { self.x = newValue }
    }
    var componentVertical: Component {
        get { self.y }
        set { self.y = newValue }
    }
}

extension CGSize: KHAxisGeometry_Editable
{
    typealias Component = CGFloat
    
    var componentHorizontal: Component {
        get { self.width }
        set { self.width = newValue }
    }
    var componentVertical: Component {
        get { self.height }
        set { self.height = newValue }
    }
}

extension CGRect: KHAxisGeometry_Editable
{
    var componentHorizontal: Component {
        get { .init(self.left, self.width) }
        set { self.left = newValue.origin; self.width = newValue.size }
    }
    var componentVertical: Component {
        get { .init(self.top, self.height) }
        set { self.top = newValue.origin; self.height = newValue.size }
    }
    
    struct Component: Equatable
    {
        var origin: CGPoint.Component
        var size: CGSize.Component
                
        var start: CGFloat {
            get {
                self.origin
            }
            set {
                self.origin = newValue
            }
        }
        var end: CGFloat {
            get {
                self.origin + self.size
            }
            set {
                self.origin = newValue - self.size
            }
        }
        var center: CGFloat {
            return self.origin + self.size / 2
        }
        
        func contains(_ frame: Self) -> Bool
        {
            self.start <= frame.start && self.end >= frame.end
        }
        
        func isInside(_ start: CGFloat, _ end: CGFloat) -> Bool
        {
            start <= self.start && self.end <= end
        }
        
        init(_ origin: CGPoint.Component, _ size: CGSize.Component)
        {
            self.origin = origin
            self.size = size
        }
        
        static let zero: Self = .init(0, 0)
    }
}


extension UIEdgeInsets: KHAxisGeometry_Editable
{
    var componentHorizontal: Component {
        get { .init(self.left, self.right) }
        set { self.left = newValue.start; self.right = newValue.end }
    }
    var componentVertical: Component {
        get { .init(self.top, self.bottom) }
        set { self.top = newValue.start; self.bottom = newValue.end }
    }
    
    struct Component
    {
        var start: CGFloat
        var end: CGFloat
                
        init(_ start: CGFloat, _ end: CGFloat)
        {
            self.start = start
            self.end = end
        }
        
        static let zero: Self = .init(0, 0)
    }
}



// *************************
// *************************
// *************************


extension KHAlign: KHAxisGeometry_Editable
{
    var componentHorizontal: Component {
        get {
            var align: Component = .center
            
            if  self.contains(.left) {
                align.insert(.start)
            }
            if  self.contains(.right) {
                align.insert(.end)
            }
            if  self.contains(.leftOutside) {
                align.insert(.startOutside)
            }
            if  self.contains(.rightOutside) {
                align.insert(.endOutside)
            }
            return align
        }
        set {
            if  newValue.contains(.start) {
                self.insert(.left)
            }
            if  newValue.contains(.end) {
                self.insert(.right)
            }
            if  newValue.contains(.startOutside) {
                self.insert(.leftOutside)
            }
            if  newValue.contains(.endOutside) {
                self.insert(.rightOutside)
            }
        }
    }
    
    var componentVertical: Component {
        get {
            var align: Component = .center
            
            if  self.contains(.top) {
                align.insert(.start)
            }
            if  self.contains(.bottom) {
                align.insert(.end)
            }
            if  self.contains(.topOutside) {
                align.insert(.startOutside)
            }
            if  self.contains(.bottomOutside) {
                align.insert(.endOutside)
            }
            return align
        }
        set {
            if  newValue.contains(.start) {
                self.insert(.top)
            }
            if  newValue.contains(.end) {
                self.insert(.bottom)
            }
            if  newValue.contains(.startOutside) {
                self.insert(.topOutside)
            }
            if  newValue.contains(.endOutside) {
                self.insert(.bottomOutside)
            }
        }
    }
    
    struct Component : OptionSet
    {
        public var rawValue: Int
        
        public static let center = Self()
        public static let start  = Self(rawValue: 1 << 0)
        public static let end  = Self(rawValue: 1 << 1)
        
        public static let startOutside = Self(rawValue: 1 << 2)
        public static let endOutside = Self(rawValue: 1 << 3)
        
        public func simplify() -> Self {
            
            var align = self
            
            if  align.contains([.start, .end]) {
                align.remove([.start, .end])
            }
            
            if  align.contains([.startOutside, .endOutside]) {
                align.remove([.startOutside, .endOutside])
            }
            
            if (align.contains(.start) || align.contains(.end)) && (align.contains(.startOutside) || align.contains(.endOutside)) {
                align.remove([.start, .end])
            }
            
            return align
        }
        
        func moveInside() -> Self
        {
            var align = self
            
            if  align.remove(.startOutside) != nil {
                align.formUnion(.start)
            }
            
            if  align.remove(.endOutside) != nil {
                align.formUnion(.end)
            }
            
            return align
        }
        
        func moveOutside() -> Self
        {
            var align = self
            
            if  align.remove(.start) != nil {
                align.formUnion(.startOutside)
            }
            
            if  align.remove(.end) != nil {
                align.formUnion(.endOutside)
            }
                        
            return align
        }
        
        func merging(_ align: Self) -> Self
        {
            var result = self
            result.insert(align)
            
            return result
        }
        
        var anchor: CGPoint.Component
        {
            let align = self.simplify()
            var anchor: CGFloat = 0
            
            if align.contains(.start) {
                // do nothing
            } else if align.contains(.end) {
                anchor = 1
            } else {
                anchor = 0.5
            }
            
            return anchor
        }
    }
    
    static let zero: Self = []
}
