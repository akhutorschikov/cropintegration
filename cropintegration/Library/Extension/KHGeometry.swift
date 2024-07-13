//
//  KHFrame.swift
//  kh-kit
//
//  Created by Alex Khuala on 1/21/18.
//  Copyright © 2018 Alex Khuala. All rights reserved.
//

import UIKit

public extension OptionSet
{
    func intersects(_ other: Self) -> Bool
    {
        return !self.isDisjoint(with: other);
    }
}

public struct KHAlign : OptionSet {
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue;
    }
    
    public static let center = KHAlign()
    public static let left   = KHAlign(rawValue: 1 << 0)
    public static let right  = KHAlign(rawValue: 1 << 1)
    public static let top    = KHAlign(rawValue: 1 << 2)
    public static let bottom = KHAlign(rawValue: 1 << 3)
    
    public static let leftOutside    = KHAlign(rawValue: 1 << 4)
    public static let rightOutside   = KHAlign(rawValue: 1 << 5)
    public static let topOutside     = KHAlign(rawValue: 1 << 6)
    public static let bottomOutside  = KHAlign(rawValue: 1 << 7)
    
    public static let width  = KHAlign(rawValue: 1 << 8) // used only when layout 2 and more elements, = center otherwise
    public static let height = KHAlign(rawValue: 1 << 9) // used only when layout 2 and more elements, = center otherwise
    
    public func simplify() -> KHAlign {
        
        var align = self
        
        if (align.contains([.left, .right])) {
            align.remove([.left, .right])
        }
        
        if (align.contains([.top, .bottom])) {
            align.remove([.top, .bottom])
        }
        
        if (align.contains([.leftOutside, .rightOutside])) {
            align.remove([.leftOutside, .rightOutside])
        }
        
        if (align.contains([.topOutside, .bottomOutside])) {
            align.remove([.topOutside, .bottomOutside])
        }
        
        if (align.contains(.left) || align.contains(.right)) && (align.contains(.leftOutside) || align.contains(.rightOutside)) {
            align.remove([.left, .right])
        }
        
        if (align.contains(.top) || align.contains(.bottom)) && (align.contains(.topOutside) || align.contains(.bottomOutside)) {
            align.remove([.top, .bottom])
        }
        
        if (align.contains(.width) && (align.contains(.left) || align.contains(.right) || align.contains(.leftOutside) || align.contains(.rightOutside))) {
            align.remove(.width)
        }
        
        if (align.contains(.height) && (align.contains(.top) || align.contains(.bottom) || align.contains(.topOutside) || align.contains(.bottomOutside))) {
            align.remove(.height)
        }
        
        return align
    }
    
/*!
 @brief Replace all outside align to inside equivalents
 */
    public func moveInside() -> KHAlign
    {
        var align = self
        
        if (align.contains(.leftOutside)) {
            align.remove(.leftOutside)
            align.formUnion(.left)
        }
        
        if (align.contains(.rightOutside)) {
            align.remove(.rightOutside)
            align.formUnion(.right)
        }
        
        if (align.contains(.topOutside)) {
            align.remove(.topOutside)
            align.formUnion(.top)
        }
        
        if (align.contains(.bottomOutside)) {
            align.remove(.bottomOutside)
            align.formUnion(.bottom)
        }
        
        return align
    }
    
    public func moveOutside() -> KHAlign
    {
        var align = self
        
        if (align.contains(.left)) {
            align.remove(.left)
            align.formUnion(.leftOutside)
        }
        
        if (align.contains(.right)) {
            align.remove(.right)
            align.formUnion(.rightOutside)
        }
        
        if (align.contains(.top)) {
            align.remove(.top)
            align.formUnion(.topOutside)
        }
        
        if (align.contains(.bottom)) {
            align.remove(.bottom)
            align.formUnion(.bottomOutside)
        }
        
        return align
    }
    
    public func merging(_ align: KHAlign) -> KHAlign
    {
        var result = self
        result.insert(align)
        
        return result
    }
    
    public var anchor: CGPoint
    {
        let align = self.simplify()
        var anchor = KHPoint(0)
        
        if align.contains(.left) {
            // do nothing
        } else if align.contains(.right) {
            anchor.x = 1
        } else {
            anchor.x = 0.5
        }
        
        if align.contains(.top) {
            // do nothing
        } else if align.contains(.bottom) {
            anchor.y = 1
        } else {
            anchor.y = 0.5
        }
        
        return anchor
    }
}

// MARK: - Ratio

public func KHRatio(_ a: CGFloat, _ b: CGFloat, _ inverted: Bool) -> CGFloat
{
    return a == 0 || b == 0 ? 0 : (inverted ? b / a : a / b);
}

public func KHRatio(_ a: CGFloat, _ b: CGFloat) -> CGFloat
{
    return KHRatio(a, b, false);
}

// MARK: - Value

public extension CGFloat
{
    func putInside(_ start: CGFloat, _ end: CGFloat) -> CGFloat
    {
        let min = fmin(start, end);
        let max = fmax(start, end);
        
        if (self > max) {
            return max;
        }
        
        if (self < min) {
            return min;
        }
        
        return self;
    }
    
    func inside(_ one: CGFloat, _ two: CGFloat) -> Bool
    {
        let min = fmin(one, two)
        let max = fmax(one, two)
        
        return self >= min && self <= max
    }
    
    func round(_ factor: CGFloat, _ rule: FloatingPointRoundingRule) -> CGFloat
    {
        if (factor == 1 || factor == 0) {
            return self.rounded(rule)
        } else {
            return (self / factor).rounded(rule) * factor;
        }
    }
    
    func round(_ factor: CGFloat) -> CGFloat
    {
        return self.round(factor, .toNearestOrAwayFromZero);
    }
    
    func round(_ rule: FloatingPointRoundingRule) -> CGFloat
    {
        return self.rounded(rule);
    }
    
    func round() -> CGFloat
    {
        return self.rounded()
    }
    
    func pixelRound(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGFloat
    {
        return self.round(KHPixel, rule);
    }
    
    func isApproxEqual(to value: CGFloat, accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        abs(self - value) <= abs(accuracy)
    }
    
    func isApproxZero(accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        self.isApproxEqual(to: 0, accuracy: accuracy)
    }
    
    var pixelValue: CGFloat
    {
        return self * UIScreen.main.scale;
    }
    
    var size: CGSize
    {
        return KHSize(self)
    }
    
    var point: CGPoint
    {
        return KHPoint(self)
    }
    
    var inset: KHInset
    {
        return KHInset(self)
    }
    
}

public func CGFloatFromPixelValue(_ pixelValue: CGFloat) -> CGFloat
{
    return pixelValue / UIScreen.main.scale;
}

// MARK: - Inset

public typealias KHInset = UIEdgeInsets
public extension KHInset
{
    init(_ inset: CGFloat)
    {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    init(left: CGFloat = 0, top: CGFloat = 0, right: CGFloat = 0, bottom: CGFloat = 0)
    {
        self.init(top: top, left: left, bottom: bottom, right: right)
    }
    
    init(x: CGFloat = 0, y: CGFloat = 0)
    {
        self.init(top: y, left: x, bottom: y, right: x)
    }
    
    func scale(_ x: CGFloat, _ y: CGFloat) -> Self
    {
        return KHInset(top: self.top * y,
                       left: self.left * x,
                       bottom: self.bottom * y,
                       right: self.right * x)
    }
    
    func scale(_ scale: CGPoint) -> Self
    {
        self.scale(scale.x, scale.y)
    }
    
    func scale(_ scale: CGFloat) -> KHInset
    {
        self.scale(scale, scale)
    }
    
    func merge(_ inset: KHInset) -> KHInset
    {
        return KHInset(top: self.top + inset.top, left: self.left + inset.left, bottom: self.bottom + inset.bottom, right: self.right + inset.right)
    }
    
    func left(_ newLeft: CGFloat) -> KHInset
    {
        var inset = self
        inset.left = newLeft
        
        return inset
    }
    
    func right(_ newRight: CGFloat) -> KHInset
    {
        var inset = self
        inset.right = newRight
        
        return inset
    }
    
    func x(_ newX: CGFloat) -> KHInset
    {
        var inset = self
        inset.left  = newX
        inset.right = newX
        
        return inset
    }
    
    func top(_ newTop: CGFloat) -> KHInset
    {
        var inset = self
        inset.top = newTop
        
        return inset
    }
    
    func bottom(_ newBottom: CGFloat) -> KHInset
    {
        var inset = self
        inset.bottom = newBottom
        
        return inset
    }
    
    func y(_ newY: CGFloat) -> KHInset
    {
        var inset = self
        inset.top    = newY
        inset.bottom = newY
        
        return inset
    }
    
    var x: CGFloat
    {
        get {
            return self.left;
        }
        set {
            self.left = newValue;
            self.right = newValue;
        }
    }
    
    var y: CGFloat
    {
        get {
            return self.top;
        }
        set {
            self.top = newValue;
            self.bottom = newValue;
        }
    }
    
    var width: CGFloat {
        self.left + self.right
    }
    
    var height: CGFloat {
        self.top + self.bottom
    }
    
    var point: CGPoint
    {
        .init(x: self.x, y: self.y)
    }
    
    /*!
     @brief Update insets by the following (delta) values.
     */
    func adjust(left: CGFloat = 0, right: CGFloat = 0, top: CGFloat = 0, bottom: CGFloat = 0) -> KHInset
    {
        var inset = self
        inset.left   += left
        inset.right  += right
        inset.top    += top
        inset.bottom += bottom
        
        return inset
    }
    
    var vertical: KHInset
    {
        return .init(top: self.top, bottom: self.bottom)
    }
    
    var horizontal: KHInset
    {
        return .init(left: self.left, right: self.right)
    }
    
    /*!
     @brief Get maximum of both insets
     */
    func expand(to inset: KHInset) -> KHInset
    {
        var newInset = KHInset()
        newInset.left   = max(self.left,   inset.left)
        newInset.right  = max(self.right,  inset.right)
        newInset.top    = max(self.top,    inset.top)
        newInset.bottom = max(self.bottom, inset.bottom)
        
        return newInset
    }
    
    /*!
     @brief Get minimum of both insets
     */
    func narrow(to inset: KHInset) -> KHInset
    {
        var newInset = KHInset()
        newInset.left   = min(self.left,   inset.left)
        newInset.right  = min(self.right,  inset.right)
        newInset.top    = min(self.top,    inset.top)
        newInset.bottom = min(self.bottom, inset.bottom)
        
        return newInset
    }
    
    func rotate(clockwise: Bool, _ condition: Bool = true) -> Self
    {
        guard condition else {
            return self
        }
        
        var newInset = KHInset()
        if  clockwise {
            newInset.top    = self.left
            newInset.right  = self.top
            newInset.bottom = self.right
            newInset.left   = self.bottom
        } else {
            newInset.top    = self.right
            newInset.right  = self.bottom
            newInset.bottom = self.left
            newInset.left   = self.top
        }
        
        return newInset
    }
    
    func round(_ factor: CGFloat, _ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> KHInset
    {
        return KHInset(top: self.top.round(factor, rule), left: self.left.round(factor, rule), bottom: self.bottom.round(factor, rule), right: self.right.round(factor, rule))
    }
    
    func round(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> KHInset
    {
        return KHInset(top: self.top.round(rule), left: self.left.round(rule), bottom: self.bottom.round(rule), right: self.right.round(rule))
    }
    
    func pixelRound(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> KHInset
    {
        return KHInset(top: self.top.pixelRound(rule), left: self.left.pixelRound(rule), bottom: self.bottom.pixelRound(rule), right: self.right.pixelRound(rule))
    }
    
    func isApproxEqual(to inset: Self, accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        self.left.isApproxEqual(to: inset.left, accuracy: accuracy) &&
        self.top.isApproxEqual(to: inset.top, accuracy: accuracy) &&
        self.right.isApproxEqual(to: inset.right, accuracy: accuracy) &&
        self.bottom.isApproxEqual(to: inset.bottom, accuracy: accuracy)
    }
    
    func isApproxZero(accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        self.left.isApproxZero(accuracy: accuracy) &&
        self.top.isApproxZero(accuracy: accuracy) &&
        self.right.isApproxZero(accuracy: accuracy) &&
        self.bottom.isApproxZero(accuracy: accuracy)
    }
}

public extension KHInset /* Overloading */
{
    static prefix func -(a: Self) -> Self
    {
        .init(top: -a.top, left: -a.left, bottom: -a.bottom, right: -a.right)
    }
    
    static func +(a: Self, b: Self) -> Self
    {
        .init(top: a.top + b.top, left: a.left + b.left, bottom: a.bottom + b.bottom, right: a.right + b.right)
    }
    
    static func -(a: Self, b: Self) -> Self
    {
        .init(top: a.top - b.top, left: a.left - b.left, bottom: a.bottom - b.bottom, right: a.right - b.right)
    }
    
    static func *(a: Self, b: CGPoint) -> Self
    {
        .init(top: a.top * b.y, left: a.left * b.x, bottom: a.bottom * b.y, right: a.right * b.x)
    }
    static func *(a: Self, b: CGFloat) -> Self
    {
        .init(top: a.top * b, left: a.left * b, bottom: a.bottom * b, right: a.right * b)
    }
    static func *(a: Self, b: Int) -> Self
    {
        return a * CGFloat(b)
    }
    
    static func +=(a: inout Self, b: Self)
    {
        a.top      += b.top
        a.left     += b.left
        a.bottom   += b.bottom
        a.right    += b.right
    }
    static func -=(a: inout Self, b: Self)
    {
        a.top      -= b.top
        a.left     -= b.left
        a.bottom   -= b.bottom
        a.right    -= b.right
    }
    
    static func *=(a: inout Self, b: CGPoint)
    {
        a.top      *= b.y
        a.left     *= b.x
        a.bottom   *= b.y
        a.right    *= b.x
    }
    static func *=(a: inout Self, b: CGFloat)
    {
        a.top      *= b
        a.left     *= b
        a.bottom   *= b
        a.right    *= b
    }
    static func *=(a: inout Self, b: Int)
    {
        a *= CGFloat(b)
    }
}


// MARK: - Size

public typealias KHSize = CGSize
public extension KHSize {
    
    init(_ width: CGFloat, _ height: CGFloat)
    {
        self.init(width: width, height: height)
    }
    
    init(_ size: CGFloat)
    {
        self.init(size, size)
    }
    
    init(width: CGFloat)
    {
        self.init(width, 0)
    }
    
    init(height: CGFloat)
    {
        self.init(0, height)
    }
    
    init(_ array: [CGFloat])
    {
        var width  = CGFloat(0)
        var height = CGFloat(0)
        
        if (array.count > 0) {
            width = array[0]
            if (array.count > 1) {
                height = array[1]
            }
        }
        self.init(width, height)
    }
    
    func inset(_ inset: KHInset) -> Self
    {
        return KHSize(fmax(0, self.width - inset.left - inset.right), fmax(0, self.height - inset.top - inset.bottom));
    }
    
    func inset(value: CGFloat) -> Self
    {
        return self.inset(.init(value))
    }
    
    func rotate(_ condition: Bool = true) -> CGSize
    {
        if (!condition) {
            return self
        }
        
        return KHSize(self.height, self.width)
    }
    
    func scale(_ sx: CGFloat, _ sy: CGFloat) -> Self
    {
        return KHSize(self.width * sx, self.height * sy)
    }
    
    func scale(_ scale: CGFloat) -> Self
    {
        return self.scale(scale, scale)
    }
    
    func scale(_ point: CGPoint) -> Self
    {
        return self.scale(point.x, point.y)
    }
    
    func expand(to size: Self) -> Self
    {
        .init(max(self.width, size.width), max(self.height, size.height))
    }
    
    func narrow(to size: Self) -> Self
    {
        .init(min(self.width, size.width), min(self.height, size.height))
    }
    
    func multiplier(to size: Self) -> CGPoint
    {
        .init(KHRatio(size.width, self.width), KHRatio(size.height, self.height))
    }
    
    func width(_ newWidth: CGFloat) -> CGSize
    {
        var size = self
        size.width = newWidth
        
        return size
    }
    
    func height(_ newHeight: CGFloat) -> CGSize
    {
        var size = self
        size.height = newHeight
        
        return size
    }
    
    func incWidth(_ dw: CGFloat) -> CGSize
    {
        var size = self
        size.width += dw
        
        return size
    }
    
    func incHeight(_ dh: CGFloat) -> CGSize
    {
        var size = self
        size.height += dh
        
        return size
    }
    
    var ratio: CGFloat
    {
        return KHRatio(self.width, self.height);
    }

    func ratio(_ ratio: CGFloat, _ inner: Bool) -> CGSize
    {
        var newSize = KHSize(0);
        
        if (ratio == 0) {
            newSize = self;
        } else if (self.height != 0) {
            
            if (inner != (ratio < self.ratio)) {
                newSize.width  = self.width;
                newSize.height = self.width  / ratio;
            } else {
                newSize.width  = self.height * ratio;
                newSize.height = self.height;
            }
        }
        
        return newSize;
    }
    
    func point(at anchor: CGPoint, relativeTo relativeAnchor: CGPoint = .init(0)) -> CGPoint
    {
        return self.scale(anchor - relativeAnchor).point
    }
    
    func anchor(for point: CGPoint, relativeTo relativeAnchor: CGPoint = .init(0)) -> CGPoint
    {
        let sx = self.width  != 0 ? point.x / self.width  : 0
        let sy = self.height != 0 ? point.y / self.height : 0
        
        return relativeAnchor + KHPoint(sx, sy)
    }
    
    func pointInside(_ align: KHAlign) -> CGPoint
    {
        return self.bounds.pointInside(align);
    }
    
    var pixelSize: CGSize
    {
        return KHSize(self.width.pixelValue, self.height.pixelValue);
    }
    
    var center: CGPoint
    {
        return self.pointInside(.center);
    }
    
    var bounds: CGRect
    {
        return KHFrame(x: 0, y: 0, width: self.width, height: self.height);
    }
    
    var point: CGPoint
    {
        return KHPoint(self.width, self.height)
    }
    
    var minSize: CGFloat
    {
        return min(self.width, self.height);
    }
    
    var maxSize: CGFloat
    {
        return max(self.width, self.height);
    }
    
    var array: [CGFloat]
    {
        return [self.width, self.height]
    }
    
    var square: Bool
    {
        return self.width == self.height
    }
    
    var landscape: Bool
    {
        return self.width > self.height
    }
    
    var portrait: Bool
    {
        return self.width < self.height
    }
    
    var landscapeSize: CGSize
    {
        return self.width > self.height ? self : self.rotate()
    }
    
    var portraitSize: CGSize
    {
        return self.width < self.height ? self : self.rotate()
    }
    
    func round(_ factor: CGFloat, _ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGSize
    {
        return KHSize(self.width.round(factor, rule), self.height.round(factor, rule));
    }
    
    func round(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGSize
    {
        return KHSize(self.width.round(rule), self.height.round(rule));
    }
    
    func pixelRound(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGSize
    {
        return KHSize(self.width.pixelRound(rule), self.height.pixelRound(rule));
    }
    
    func isApproxEqual(to size: Self, accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        self.width.isApproxEqual(to: size.width, accuracy: accuracy) && self.height.isApproxEqual(to: size.height, accuracy: accuracy)
    }
    
    func isApproxZero(accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        self.width.isApproxZero(accuracy: accuracy) && self.height.isApproxZero(accuracy: accuracy)
    }
    
    func desqueeze(_ desqueeze: CGFloat?, accuracy: CGFloat) -> CGSize
    {
        guard let d = desqueeze, d > 0, d != 1, abs(self.width - self.height) > abs(accuracy) else {
            return self
        }
        
        var a = self.width
        var b = self.height
        
        if  a > b {
            a *= d
        } else {
            b *= d
        }
        
        return .init(a, b)
    }
    
    func multiplier(for desqueeze: CGFloat?, accuracy: CGFloat) -> CGPoint
    {
        var multiplier: CGPoint = .init(1)
        
        guard let d = desqueeze, d > 0, d != 1, abs(self.width - self.height) > abs(accuracy) else {
            return multiplier
        }
        
        if  self.width > self.height {
            multiplier.x = d
        } else {
            multiplier.y = d
        }
        
        return multiplier
    }
    
    static let standard = KHSize(100)
}

extension KHSize: Hashable
{
    static func == (lhs: KHSize, rhs: KHSize) -> Bool
    {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
}

public extension KHSize
{
    static prefix func -(a: Self) -> Self
    {
        return .init(-a.width, -a.height)
    }
    
    static func +(a: Self, b: Self) -> Self
    {
        return .init(a.width + b.width, a.height + b.height)
    }
    static func +(a: Self, b: CGPoint) -> Self
    {
        return .init(a.width + b.x, a.height + b.y)
    }
    static func +(a: Self, b: CGFloat) -> Self
    {
        return .init(a.width + b, a.height + b)
    }
    static func +(a: Self, b: Int) -> Self
    {
        return a + CGFloat(b)
    }
    static func -(a: Self, b: Self) -> Self
    {
        return .init(a.width - b.width, a.height - b.height)
    }
    static func -(a: Self, b: CGPoint) -> Self
    {
        return .init(a.width - b.x, a.height - b.y)
    }
    static func -(a: Self, b: CGFloat) -> Self
    {
        return .init(a.width - b, a.height - b)
    }
    static func -(a: Self, b: Int) -> Self
    {
        return a - CGFloat(b)
    }
    static func *(a: Self, b: Self) -> Self
    {
        return .init(a.width * b.width, a.height * b.height)
    }
    static func *(a: Self, b: CGPoint) -> Self
    {
        return .init(a.width * b.x, a.height * b.y)
    }
    static func *(a: Self, b: CGFloat) -> Self
    {
        return .init(a.width * b, a.height * b)
    }
    static func *(a: Self, b: Int) -> Self
    {
        return a * CGFloat(b)
    }
    
    static func +=(a: inout Self, b: Self)
    {
        a.width += b.width
        a.height += b.height
    }
    static func +=(a: inout Self, b: CGPoint)
    {
        a.width += b.x
        a.height += b.y
    }
    static func +=(a: inout Self, b: CGFloat)
    {
        a.width += b
        a.height += b
    }
    static func +=(a: inout Self, b: Int)
    {
        a += CGFloat(b)
    }
    static func -=(a: inout Self, b: Self)
    {
        a.width -= b.width
        a.height -= b.height
    }
    static func -=(a: inout Self, b: CGPoint)
    {
        a.width -= b.x
        a.height -= b.y
    }
    static func -=(a: inout Self, b: CGFloat)
    {
        a.width -= b
        a.height -= b
    }
    static func -=(a: inout Self, b: Int)
    {
        a -= CGFloat(b)
    }
    static func *=(a: inout Self, b: Self)
    {
        a.width *= b.width
        a.height *= b.height
    }
    static func *=(a: inout Self, b: CGPoint)
    {
        a.width *= b.x
        a.height *= b.y
    }
    static func *=(a: inout Self, b: CGFloat)
    {
        a.width *= b
        a.height *= b
    }
    static func *=(a: inout Self, b: Int)
    {
        a *= CGFloat(b)
    }
}

public func KHSizeFromPixelSize(_ pixelSize: CGSize) -> CGSize
{
    return KHSize(CGFloatFromPixelValue(pixelSize.width), CGFloatFromPixelValue(pixelSize.height));
}

// MARK: - Point

public typealias KHPoint = CGPoint
public extension KHPoint {
    
    init(_ xy: CGFloat) {
        self.init(x: xy, y: xy);
    }
    
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y);
    }
    
    init(x: CGFloat) {
        self.init(x: x, y: 0)
    }
    
    init(y: CGFloat) {
        self.init(x: 0, y: y)
    }
    
    func x(_ newX: CGFloat) -> CGPoint
    {
        var point = self;
        point.x = newX;
        
        return point;
    }
    
    func y(_ newY: CGFloat) -> CGPoint
    {
        var point = self;
        point.y = newY;
        
        return point;
    }
    
    func dx(_ dx: CGFloat) -> Self
    {
        var point = self
        point.x += dx
        
        return point
    }
    
    func dy(_ dy: CGFloat) -> Self
    {
        var point = self
        point.y += dy
        
        return point
    }
    
    func offset(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint
    {
        return CGPoint(self.x + dx, self.y + dy);
    }
    
    func offset(_ dxy: CGFloat) -> CGPoint
    {
        return self.offset(dxy, dxy);
    }
    
    func scale(_ sx: CGFloat, _ sy: CGFloat) -> CGPoint
    {
        return CGPoint(self.x * sx, self.y * sy);
    }
    
    func scale(_ sxy: CGFloat) -> CGPoint
    {
        return self.scale(sxy, sxy);
    }
    
    func scale(_ point: CGPoint) -> Self
    {
        return self.scale(point.x, point.y)
    }
    
    func rotate(_ condition: Bool = true) -> CGPoint
    {
        if (!condition) {
            return self
        }
        
        return CGPoint(self.y, self.x)
    }
    
    func rotate(_ origin: CGPoint, _ angle: CGFloat) -> CGPoint
    {
        guard angle != 0 else {
            return self
        }
        
        // get point related to origin
        var relativePoint = CGPoint();
        relativePoint.x = self.x - origin.x;
        relativePoint.y = self.y - origin.y;
        
        // rotate relative point
        let c = cos(angle);
        let s = sin(angle);
        
        var rotatedRelativePoint = CGPoint();
        rotatedRelativePoint.x = relativePoint.x * c - relativePoint.y * s;
        rotatedRelativePoint.y = relativePoint.x * s + relativePoint.y * c;
        
        // get absolute point
        var rotatedPoint = CGPoint();
        rotatedPoint.x = rotatedRelativePoint.x + origin.x;
        rotatedPoint.y = rotatedRelativePoint.y + origin.y;
        
        return rotatedPoint;
    }
    
    func rotateInsideBox(_ box: inout CGSize, _ angle: CGFloat) -> CGPoint
    {
        guard angle != 0 else {
            return self
        }
        
        // get point related to center of box
        var relativePoint = CGPoint();
        relativePoint.x = self.x - box.width  / 2;
        relativePoint.y = self.y - box.height / 2;
        
        // rotate relative point
        let c = cos(angle);
        let s = sin(angle);
        
        var rotatedRelativePoint = CGPoint();
        rotatedRelativePoint.x = relativePoint.x * c - relativePoint.y * s;
        rotatedRelativePoint.y = relativePoint.x * s + relativePoint.y * c;
        
        // rotate box
        let rotatedBox = box.bounds.applying(CGAffineTransform(rotationAngle: angle)).size;
        
        // get absolute point
        var rotatedPoint = CGPoint();
        rotatedPoint.x = rotatedRelativePoint.x + rotatedBox.width  / 2;
        rotatedPoint.y = rotatedRelativePoint.y + rotatedBox.height / 2;
        
        box = rotatedBox
        
        return rotatedPoint;
    }
    
    func flip(_ origin: CGPoint, _ horizontally: Bool) -> CGPoint
    {
        var flippedPoint = self;
        
        if (horizontally) {
            flippedPoint.x = -1 * (self.x - origin.x) + origin.x;
        } else {
            flippedPoint.y = -1 * (self.y - origin.y) + origin.y;
        }
        
        return flippedPoint;
    }
    
    func flip(_ horizontally: Bool) -> CGPoint
    {
        return self.flip(CGPoint(), horizontally);
    }
    
    func putInside(_ frame: CGRect) -> CGPoint
    {
        let x = self.x.putInside(frame.left, frame.right);
        let y = self.y.putInside(frame.top, frame.bottom);
        
        return KHPoint(x, y);
    }
    
    /*!
     @brief Get maximum of both points
     */
    func expand(to point: CGPoint) -> CGPoint
    {
        var newPoint = self
        newPoint.x = max(self.x, point.x)
        newPoint.y = max(self.y, point.y)
        
        return newPoint
    }
    
    func expand(to value: CGFloat) -> CGPoint
    {
        var newPoint = self
        newPoint.x = max(self.x, value)
        newPoint.y = max(self.y, value)
        
        return newPoint
    }
    
    /*!
     @brief Get minimum of both points
     */
    func narrow(to point: CGPoint) -> CGPoint
    {
        var newPoint = self
        newPoint.x = min(self.x, point.x)
        newPoint.y = min(self.y, point.y)
        
        return newPoint
    }
    func narrow(to value: CGFloat) -> CGPoint
    {
        var newPoint = self
        newPoint.x = min(self.x, value)
        newPoint.y = min(self.y, value)
        
        return newPoint
    }
    
    func round(_ factor: CGFloat, _ rule: FloatingPointRoundingRule) -> CGPoint
    {
        return CGPoint(self.x.round(factor, rule), self.y.round(factor, rule));
    }
    
    func round(_ factor: CGFloat) -> CGPoint
    {
        return self.round(factor, .toNearestOrAwayFromZero)
    }
    
    func round(_ rule: FloatingPointRoundingRule) -> CGPoint
    {
        return CGPoint(self.x.round(rule), self.y.round(rule));
    }
    
    func round() -> CGPoint
    {
        return self.round(.toNearestOrAwayFromZero);
    }
    
    func pixelRound(_ rule: FloatingPointRoundingRule) -> CGPoint
    {
        return CGPoint(self.x.pixelRound(rule), self.y.pixelRound(rule));
    }
    
    func pixelRound() -> CGPoint
    {
        return self.pixelRound(.toNearestOrAwayFromZero);
    }
    
    func isApproxEqual(to point: Self, accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        self.x.isApproxEqual(to: point.x, accuracy: accuracy) && self.y.isApproxEqual(to: point.y, accuracy: accuracy)
    }
    
    func isApproxZero(accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        self.x.isApproxZero(accuracy: accuracy) && self.y.isApproxZero(accuracy: accuracy)
    }
    
    var frame: CGRect
    {
        return CGRect(origin: self, size: CGSize());
    }
    
    var size: CGSize
    {
        return KHSize(self.x, self.y)
    }
    
    var ratio: CGFloat
    {
        return KHRatio(self.x, self.y)
    }
    
    func ratio(_ ratio: CGFloat, _ inner: Bool) -> CGPoint
    {
        return self.size.ratio(ratio, inner).point
    }
}

public extension KHPoint
{
    static prefix func -(a: Self) -> Self
    {
        return .init(-a.x, -a.y)
    }
    
    static func +(a: Self, b: Self) -> Self
    {
        return .init(a.x + b.x, a.y + b.y)
    }
    static func +(a: Self, b: CGFloat) -> Self
    {
        return .init(a.x + b, a.y + b)
    }
    static func +(a: Self, b: Int) -> Self
    {
        return a + CGFloat(b)
    }
    static func -(a: Self, b: Self) -> Self
    {
        return .init(a.x - b.x, a.y - b.y)
    }
    static func -(a: Self, b: CGFloat) -> Self
    {
        return .init(a.x - b, a.y - b)
    }
    static func -(a: Self, b: Int) -> Self
    {
        return a - CGFloat(b)
    }
    static func *(a: Self, b: Self) -> Self
    {
        return .init(a.x * b.x, a.y * b.y)
    }
    static func *(a: Self, b: CGFloat) -> Self
    {
        return .init(a.x * b, a.y * b)
    }
    static func *(a: Self, b: Int) -> Self
    {
        return a * CGFloat(b)
    }
    
    static func +=(a: inout Self, b: Self)
    {
        a.x += b.x
        a.y += b.y
    }
    static func +=(a: inout Self, b: CGFloat)
    {
        a.x += b
        a.y += b
    }
    static func +=(a: inout Self, b: Int)
    {
        a += CGFloat(b)
    }
    static func -=(a: inout Self, b: Self)
    {
        a.x -= b.x
        a.y -= b.y
    }
    static func -=(a: inout Self, b: CGFloat)
    {
        a.x -= b
        a.y -= b
    }
    static func -=(a: inout Self, b: Int)
    {
        a -= CGFloat(b)
    }
    static func *=(a: inout Self, b: Self)
    {
        a.x *= b.x
        a.y *= b.y
    }
    static func *=(a: inout Self, b: CGFloat)
    {
        a.x *= b
        a.y *= b
    }
    static func *=(a: inout Self, b: Int)
    {
        a *= CGFloat(b)
    }
}


public func KHPointX(_ x: CGFloat) -> CGPoint
{
    return KHPoint(x: x, y: 0);
}

public func KHPointY(_ y: CGFloat) -> CGPoint
{
    return KHPoint(x: 0, y: y);
}

// MARK: - Frame

public typealias KHFrame = CGRect
public extension KHFrame {
    
    init(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat)
    {
        self.init(x: x, y: y, width: width, height: height);
    }
    
    init(_ origin: CGPoint, _ size: CGSize)
    {
        self.init(origin.x, origin.y, size.width, size.height);
    }
    
    init(_ size: CGSize)
    {
        self.init(0, 0, size.width, size.height);
    }
    
    init(_ origin: CGPoint)
    {
        self.init(origin.x, origin.y, 0, 0);
    }
    
    init(_ p1: CGPoint, _ p2: CGPoint)
    {
        let x, w: CGFloat
        if  p1.x < p2.x {
            x = p1.x
            w = p2.x - p1.x
        } else {
            x = p2.x
            w = p1.x - p2.x
        }
        
        let y, h: CGFloat
        if  p1.y < p2.y {
            y = p1.y
            h = p2.y - p1.y
        } else {
            y = p2.y
            h = p1.y - p2.y
        }
        
        self.init(x, y, w, h)
    }
    
    func inset(_ inset: UIEdgeInsets) -> CGRect
    {
        return self.inset(by: inset);
    }
    
    func inset(value: CGFloat) -> CGRect
    {
        return self.inset(.init(value))
    }
    
    func inset(for frame: CGRect) -> UIEdgeInsets
    {
        return KHInset(left: frame.left - self.left, top: frame.top - self.top, right: self.right - frame.right, bottom: self.bottom - frame.bottom)
    }
    
    func offset(_ dx: CGFloat, _ dy: CGFloat) -> CGRect
    {
        return self.offsetBy(dx: dx, dy: dy);
    }
    
    func offset(_ point: CGPoint) -> CGRect
    {
        return self.offset(point.x, point.y);
    }
    
    func offset(_ size: CGSize) -> CGRect
    {
        return self.offset(size.width, size.height);
    }
    
    func incWidth(_ dw: CGFloat) -> CGRect
    {
        var rect = self;
        rect.width += dw;
        
        return rect;
    }
    
    func incHeight(_ dh: CGFloat) -> CGRect
    {
        var rect = self;
        rect.height += dh;
        
        return rect;
    }
    
    func inframe(_ size: CGSize, _ align: KHAlign, _ inset: UIEdgeInsets = KHInset()) -> CGRect
    {
        let align = align.simplify();
        
        let W = self.size.width;
        let H = self.size.height;
        let w, h, x, y: CGFloat;
        
        if  size.width == 0 {
            w = W - inset.left - inset.right;
            x = inset.left;
        } else {
            w = size.width;
            
            if (align.contains(.leftOutside)) {
                x = -inset.left - w;
            } else if (align.contains(.left)) {
                x = inset.left;
            } else if (align.contains(.right)) {
                x = W - w - inset.right;
            } else if (align.contains(.rightOutside)) {
                x = W + inset.right;
            } else { // center and not defined hor. align
                x = (W - w - inset.right + inset.left) / 2;
            }
        }
        if  size.height == 0 {
            h = H - inset.top - inset.bottom;
            y = inset.top;
        } else {
            h = size.height;
            
            if (align.contains(.topOutside)) {
                y = -inset.top - h;
            } else if (align.contains(.top)) {
                y = inset.top;
            } else if (align.contains(.bottom)) {
                y = H - h - inset.bottom;
            } else if (align.contains(.bottomOutside)) {
                y = H + inset.bottom;
            } else { // center and not defined vert. align
                y = (H - h - inset.bottom + inset.top) / 2;
            }
        }
        
        return CGRect.init(x: self.origin.x + x, y: self.origin.y + y, width: w, height: h)
    }
    
    func inframe(ratio: CGFloat, _ align: KHAlign, _ inset: UIEdgeInsets = KHInset()) -> CGRect
    {
        let size = self.size.inset(inset).ratio(ratio, true)
        return self.inframe(size, align, inset)
    }
    
    func rotate(_ condition: Bool = true) -> CGRect
    {
        if (!condition) {
            return self
        }
        
        var rect = CGRect();
        
        rect.origin = self.origin.rotate();
        rect.size = self.size.rotate();
        
        return rect;
    }
    
    func scale(_ sx: CGFloat, _ sy: CGFloat) -> CGRect
    {
        var rect = CGRect();
        
        rect.origin = self.origin.scale(sx, sy);
        rect.size = self.size.scale(sx, sy);
        
        return rect;
    }
    
    func scale(_ sxy: CGFloat) -> CGRect
    {
        return self.scale(sxy, sxy);
    }
    
    func scale(_ point: CGPoint) -> CGRect
    {
        return self.scale(point.x, point.y)
    }
    
    func scaleLeft(_ sx: CGFloat) -> CGRect
    {
        return self.left(self.left * sx)
    }
    
    func scaleTop(_ sy: CGFloat) -> CGRect
    {
        return self.top(self.top * sy)
    }
    
    func scaleWidth(_ sx: CGFloat) -> CGRect
    {
        return self.width(self.width * sx)
    }
    
    func scaleHeight(_ sy: CGFloat) -> CGRect
    {
        return self.height(self.height * sy)
    }
    
    func left(_ newLeft: CGFloat) -> CGRect
    {
        var rect = self;
        rect.left = newLeft;
        
        return rect;
    }
    
    func top(_ newTop: CGFloat) -> CGRect
    {
        var rect = self;
        rect.top = newTop;
        
        return rect;
    }
    
    func width(_ newWidth: CGFloat) -> CGRect
    {
        var rect = self;
        rect.width = newWidth;
        
        return rect;
    }
    
    func height(_ newHeight: CGFloat) -> CGRect
    {
        var rect = self;
        rect.height = newHeight;
        
        return rect;
    }
    
    func right(_ newRight: CGFloat) -> CGRect
    {
        var rect = self;
        rect.right = newRight;
        
        return rect;
    }
    
    func bottom(_ newBottom: CGFloat) -> CGRect
    {
        var rect = self;
        rect.bottom = newBottom;
        
        return rect;
    }
    
    func origin(_ newOrigin: CGPoint) -> CGRect
    {
        var rect = self;
        rect.origin = newOrigin;
        
        return rect;
    }
    
    func size(_ newSize: CGSize) -> CGRect
    {
        var rect = self;
        rect.size = newSize;
        
        return rect;
    }
    
    func point(at anchor: CGPoint) -> CGPoint
    {
        return self.origin + self.size.point(at: anchor)
    }
    
    func anchor(for point: CGPoint) -> CGPoint
    {
        return self.size.anchor(for: point - self.origin)
    }
    
    func pointInside(_ align: KHAlign, inset: KHInset = .zero) -> CGPoint
    {
        let align = align.simplify()
        
        let W = self.size.width
        let H = self.size.height
        let x, y: CGFloat
        
        if  align.contains(.leftOutside) {
            x = -inset.left
        } else if align.contains(.left) {
            x = inset.left
        } else if align.contains(.right) {
            x = W - inset.right
        } else if align.contains(.rightOutside) {
            x = W + inset.right
        } else { // center and not defined hor. align
            x = (W - inset.right + inset.left) / 2
        }
    
        if  align.contains(.topOutside) {
            y = -inset.top
        } else if align.contains(.top) {
            y = inset.top
        } else if align.contains(.bottom) {
            y = H - inset.bottom
        } else if align.contains(.bottomOutside) {
            y = H + inset.bottom
        } else { // center and not defined vert. align
            y = (H - inset.bottom + inset.top) / 2
        }
        
        return .init(x: self.origin.x + x, y: self.origin.y + y)
    }
    
    var center: CGPoint
    {
        return self.point(at: .init(0.5))
    }
    
    var width: CGFloat
    {
        get {
            return self.size.width;
        }
        set {
            self.size = self.size.width(newValue);
        }
    }
    
    var height: CGFloat
    {
        get {
            return self.size.height;
        }
        set {
            self.size = self.size.height(newValue);
        }
    }
    
    var left: CGFloat
    {
        get {
            return self.origin.x;
        }
        set {
            self.origin = self.origin.x(newValue);
        }
    }
    
    var top: CGFloat
    {
        get {
            return self.origin.y;
        }
        set {
            self.origin = self.origin.y(newValue);
        }
    }
    
    var right: CGFloat
    {
        get {
            return self.left + self.width;
        }
        set {
            self.left = newValue - self.width;
        }
    }
    
    var bottom: CGFloat
    {
        get {
            self.top + self.height;
        }
        set {
            self.top = newValue - self.height;
        }
    }
    
    var end: CGPoint
    {
        get {
            .init(self.right, self.bottom)
        }
        set {
            self.origin = .init(newValue.x - self.width, newValue.y - self.height)
        }
    }
    
    func leftInverted(inside bounds: CGRect) -> CGFloat
    {
        return bounds.right - self.left
    }
    mutating func leftInverted(_ newValue: CGFloat, inside bounds: CGRect)
    {
        self.left = bounds.right - newValue
    }
    
    func rightInverted(inside bounds: CGRect) -> CGFloat
    {
        return bounds.right - self.right;
    }
    mutating func rightInverted(_ newValue: CGFloat, inside bounds: CGRect)
    {
        self.right = bounds.right - newValue;
    }
    
    func topInverted(inside bounds: CGRect) -> CGFloat
    {
        return bounds.bottom - self.top;
    }
    mutating func topInverted(_ newValue: CGFloat, inside bounds: CGRect)
    {
        self.top = bounds.bottom - newValue;
    }
    
    func bottomInverted(inside bounds: CGRect) -> CGFloat
    {
        return bounds.bottom - self.bottom;
    }
    mutating func bottomInverted(_ newValue: CGFloat, inside bounds: CGRect)
    {
        self.bottom = bounds.bottom - newValue;
    }
    
/*!
     @brief Moves frame to get inside target frame
     @discussion When target width/height is lower than
     current width/height, resulting frame is placed in
     the middle of target frame's exceeded axis
 */
    func putInside(_ frame: CGRect) -> CGRect
    {
        var limitFrame = frame
        limitFrame.width  -= self.width
        limitFrame.height -= self.height
        
        var frame  = KHFrame();
        frame.size = self.size;
        frame.origin = self.origin.putInside(limitFrame)
        
        return frame;
    }
    
    func narrow(to frame: Self) -> Self
    {
        let left = max(self.left, frame.left)
        let top = max(self.top, frame.top)
        let width = max(0, min(self.right, frame.right) - left)
        let height = max(0, min(self.bottom, frame.bottom) - top)
        
        return .init(left, top, width, height)
    }
    
    func expand(to frame: Self) -> Self
    {
        let left = min(self.left, frame.left)
        let top = min(self.top, frame.top)
        let width = max(self.right, frame.right) - left
        let height = max(self.bottom, frame.bottom) - top
        
        return .init(left, top, width, height)
    }
    
    func intersectsInside(_ frame: Self, _ inset: UIEdgeInsets) -> Bool
    {
        self.right - inset.right > frame.left  &&
        self.left + inset.left < frame.right   &&
        self.bottom - inset.bottom > frame.top &&
        self.top + inset.top < frame.bottom
    }
    
    func round(_ factor: CGFloat, _ startRule: FloatingPointRoundingRule, _ endRule: FloatingPointRoundingRule) -> CGRect
    {
        var rect = CGRect()
        
        // if use size.round + origin.round this cause double rounding for right and bottom side
        // to avoid this it needs to make separate rounding for right and bottom side and calculate size
        
        rect.origin = self.origin.round(factor, startRule)
        rect.size.width  = self.right.round(factor, endRule) - rect.left
        rect.size.height = self.bottom.round(factor, endRule) - rect.top
        
        return rect
//        return CGRect(self.origin.round(factor, rule), self.size.round(factor, rule));
    }
    
    func round(_ factor: CGFloat, _ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGRect
    {
        return self.round(factor, rule, rule)
    }
    
    func round(_ rule: FloatingPointRoundingRule) -> CGRect
    {
        return self.round(1, rule)
    }
    
    func round() -> CGRect
    {
        return self.round(.toNearestOrAwayFromZero);
    }
    
    func pixelRound(_ rule: FloatingPointRoundingRule) -> CGRect
    {
        return self.round(KHPixel, rule)
    }
    
    func pixelRound() -> CGRect
    {
        return self.round(KHPixel, .toNearestOrAwayFromZero);
    }
    
    func pixelRoundText() -> CGRect
    {
        return CGRect(self.origin.pixelRound(.toNearestOrAwayFromZero), self.size.pixelRound(.up))
    }
    
    func pixelRoundPosition() -> CGRect
    {
        return CGRect(self.origin.pixelRound(.toNearestOrAwayFromZero), self.size)
    }
    
    func isApproxEqual(to frame: Self, accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        self.origin.isApproxEqual(to: frame.origin, accuracy: accuracy) &&
        self.size.isApproxEqual(to: frame.size, accuracy: accuracy)
    }
    
    func isApproxZero(accuracy: CGFloat = KHApproxAccuracy) -> Bool
    {
        self.origin.isApproxZero(accuracy: accuracy) &&
        self.size.isApproxZero(accuracy: accuracy)
    }
    
    func pixelSize(_ newPixelSize: CGSize) -> CGRect
    {
        var rect = self;
        rect.pixelSize = newPixelSize;
        
        return rect;
    }
    
    var pixelSize: CGSize
    {
        get {
            return self.size.pixelSize;
        }
        set {
            self.size = KHSizeFromPixelSize(newValue);
        }
    }
    
    func pixelWidth(_ newPixelWidth: CGFloat) -> CGRect
    {
        var rect = self;
        rect.pixelWidth = newPixelWidth;
        
        return rect;
    }
    
    var pixelWidth: CGFloat
    {
        get {
            return self.width.pixelValue;
        }
        set {
            self.width = CGFloatFromPixelValue(newValue);
        }
    }
    
    func pixelHeight(_ newPixelHeight: CGFloat) -> CGRect
    {
        var rect = self;
        rect.pixelHeight = newPixelHeight;
        
        return rect;
    }
    
    var pixelHeight: CGFloat
    {
        get {
            return self.height.pixelValue;
        }
        set {
            self.height = CGFloatFromPixelValue(newValue);
        }
    }

    static let standard = KHSize(100).bounds
    static let screen = KHSize(320).bounds
    static let bar = KHSize(320, 44).bounds
    static let line = KHSize(320, 1).bounds
}

public func KHFrameXXYY(_ left: CGFloat, _ right: CGFloat, _ top: CGFloat, _ bottom: CGFloat) -> CGRect
{
    return CGRect(left, top, right - left, bottom - top);
}

public func KHFrameCS(_ center: CGPoint, _ size: CGSize) -> CGRect
{
    return KHFrame(center.x - size.width / 2, center.y - size.height / 2, size.width, size.height)
}

// MARK: - Pixel

public let KHPixel = 1.0 / UIScreen.main.scale
public let KHApproxAccuracy: CGFloat = 0.01
