//
//  KHCropRect.swift
//  kh-kit
//
//  Created by Alex Khuala on 11/13/18.
//

import UIKit

struct KHCropRect: Codable, Equatable
{
    let maxSize: CGSize
    fileprivate(set) var angle: CGFloat = 0 // rotation in radians
    fileprivate(set) var frame: CGRect
    
    func isSafeAsDevider() -> Bool
    {
        self.frame.width > 0 && self.frame.height > 0 && self.maxSize.width > 0 && self.maxSize.height > 0
    }
    
    func scale(_ scale: CGFloat) -> Self
    {
        guard scale != 1 else {
            return self
        }
        
        return .init(maxSize: self.maxSize.scale(scale), angle: self.angle, frame: self.frame.scale(scale))
    }
    
    init(maxSize: CGSize = .init(100))
    {
        self.maxSize = maxSize
        self.frame = maxSize.bounds
    }
    
    init(maxSize: CGSize = .init(100), innerRatio: CGFloat)
    {
        self.maxSize = maxSize
        self.frame = KHFrameCS(maxSize.center, maxSize.ratio(innerRatio, true))
    }
    
    init(cropSize: CGSize = .init(100), outerRatio: CGFloat)
    {
        self.maxSize = cropSize.ratio(outerRatio, false)
        self.frame = KHFrameCS(self.maxSize.center, cropSize)
    }
    
    init(maxSize: CGSize, angle: CGFloat, frame: CGRect)
    {
        self.maxSize = maxSize
        self.angle = angle
        self.frame = frame
    }
}

extension KHCropRect /* Drawing */
{
    func paramsForPrinting(to size: CGSize, orientation: KHOrientation2) -> (CGRect, CGFloat)
    {
        let rotated = orientation.rotated
        
        var maxSize = self.maxSize
        var frame = self.frame
        let angle = self.angle
        
        // rotate back target size for orientation
        let targetSize = size.rotate(rotated)
        
        // scale to size
        let scale  = frame.size.multiplier(to: targetSize)
        if  scale != .init(1) {
            maxSize = maxSize.scale(scale)
            frame = frame.scale(scale)
        }
        
        let rect = KHFrame(frame.center.scale(-1), maxSize)
        
        return (rect, angle)
    }
}

// *************************
// *************************
// *************************

extension KHCropRect
{
    class Editor
    {
        init(with cropRect: KHCropRect, accuracy: CGFloat = 0.0001, minSize: CGFloat? = nil)
        {
            self._bounds = cropRect.maxSize.bounds
            self._minSize = minSize
            
            self._editFrame = .init(frame: cropRect.frame, angle: cropRect.angle, accuracy: abs(accuracy))
        }
        
        // MARK: - Private
        
//        private let _zero: CGFloat
        private let _minSize: CGFloat?
        
//        private var _angle: CGFloat
//        private var _frame: CGRect
        private var _bounds: CGRect
        
        private var _pushScale: CGFloat = 1
        
        private var _editFrame: EditFrame

        // experimental
        
        private struct EditFrame
        {
            init(frame: CGRect, angle: CGFloat, accuracy: CGFloat)
            {
                self.center = frame.center
                self.size = frame.size
                self.accuracy = accuracy
                self.angle = angle
            }
            
            var center: CGPoint
            var size: CGSize
            {
                didSet {
                    self._rotatedSize = nil
                }
            }
            var angle: CGFloat
            {
                didSet {
                    self._rotatedSize = nil
                    self._needsRotation = nil
                }
            }
            var frame: CGRect
            {
                KHFrameCS(self.center, self.size)
            }
            
            let accuracy: CGFloat
            
            mutating func rotatedSize() -> CGSize
            {
                if  let size = self._rotatedSize {
                    return size
                }
                
                let size = self._makeRotatedSize()
                self._rotatedSize = size

                return size
            }
            
            mutating func rotatedFrame() -> CGRect
            {
                KHFrameCS(self.center, self.rotatedSize())
            }
            
            mutating func needsRotation(in block: (_ angle: CGFloat) -> Void)
            {
                guard self.needsRotation() else {
                    return
                }
                
                block(self.angle)
            }
            
            mutating private func needsRotation() -> Bool
            {
                if  let needs = self._needsRotation {
                    return needs
                }
                
                let needs = self._makeNeedsRotation()
                self._needsRotation = needs

                return needs
            }
            
            private var _rotatedSize: CGSize?
            mutating private func _makeRotatedSize() -> CGSize
            {
                guard self.needsRotation() else {
                    return self.size
                }
                return Self.rotateSize(self.size, by: self.angle)
            }
            
            private var _needsRotation: Bool?
            private func _makeNeedsRotation() -> Bool
            {
                !Editor._isAngleCloseToZero(self.angle, accuracy: self.accuracy)
            }
            
            static func rotateSize(_ size: CGSize, by angle: CGFloat) -> CGSize
            {
                size.bounds.applying(.init(rotationAngle: angle)).standardized.size
            }
        }
    }
}

extension KHCropRect.Editor /* actions */
{
    var cropRect: KHCropRect
    {
        get {
            .init(maxSize: self._bounds.size, angle: self._editFrame.angle, frame: self._editFrame.frame)
        }
        set {
            self._bounds = newValue.maxSize.bounds
            self._editFrame = .init(frame: newValue.frame, angle: newValue.angle, accuracy: self._editFrame.accuracy)
        }
    }
    
    var contentSize: CGSize
    {
        self._editFrame.size
    }
    
    @discardableResult
    func scale(_ scale: inout CGFloat, _ anchor: CGPoint, allowsMoving: Bool = false) -> Bool
    {
        self._resetPushScale()
        
        // fix min scale
        if  let minSize = self._minSize {
            scale = Self._fixMinScale(scale, self._editFrame.size, minSize)
        }
        
        if  allowsMoving {
            
            var editFrame = self._editFrame
            editFrame.size *= scale
            
            // fix max size
            Self._fixSize(&editFrame, bounds: self._bounds)
            
            // put new size to the proper center
            Self._fixPosition(&editFrame, bounds: self._bounds)
            
            // save final result
            self._editFrame = editFrame
            
        } else {
            
            // old approach
            let frame = self._editFrame.frame
            let angle = self._editFrame.angle
            let accuracy = self._editFrame.accuracy
            
            // fix max scale
            Self.fixScale(&scale, anchor: anchor, frame: frame, angle: angle, bounds: self._bounds, accuracy: accuracy)
            
            // check scale is not 1
            guard scale != 1 else {
                return false
            }
            
            self._updateFrame(scale, anchor)
        }
        
        return true
    }
    
    @discardableResult
    func move(_ translation: CGPoint) -> Bool
    {
        self._resetPushScale()
        
        var editFrame = self._editFrame
        var translation = translation
        
        editFrame.needsRotation { angle in
            translation = translation.rotate(.zero, -angle)
        }
        
        Self.fixTranslation(&translation, frame: editFrame.rotatedFrame(), bounds: self._bounds)
        
        // check delta is not a zero
        guard self._isNotZero(translation, accuracy: editFrame.accuracy) else {
            return false
        }
        
        self._editFrame.center += translation
        
        return true
    }
    
    public func rotate(_ angle: CGFloat)
    {
        self._editFrame.angle = angle
        
        var scale = self._pushScale
        let frame = self._editFrame.frame
        let anchor = KHPoint(0.5)
        let accuracy = self._editFrame.accuracy
        
        // fix max scale
        Self.fixScale(&scale, anchor: anchor, frame: frame, angle: angle, bounds: self._bounds, accuracy: accuracy)
        
        // check scale is not 1
        guard scale != 1 else {
            return
        }
        
        var pushScale = KHRatio(self._pushScale, scale)
        if  pushScale < accuracy {
            pushScale = 1
        }
        
        self._pushScale = pushScale
        self._updateFrame(scale, anchor)
    }
    
    func reset(keepingFrameRatio: Bool)
    {
        let frame: CGRect
        if  keepingFrameRatio {
            frame = self._bounds.inframe(ratio: self._editFrame.size.ratio, .center)
        } else {
            frame = self._bounds
        }
        
        self._editFrame = .init(frame: frame, angle: 0, accuracy: self._editFrame.accuracy)
    }
    
    func fix(bounds: CGRect)
    {
        self.fill(outerRatio: 1, bounds: bounds)
    }
    
    
    func fill(outerRatio: CGFloat, centered: Bool = true, bounds: CGRect? = nil)
    {
        if  let bounds = bounds {
            let scale = self._bounds.size.multiplier(to: bounds.size)
            if  scale != .init(1) {
                self._bounds.size *= scale
                self._editFrame.center *= scale
            }
        }
        
        var editFrame = self._editFrame
        let accuracy = editFrame.accuracy
        let angle = editFrame.angle
        
        if  centered {
            
            let anchor = KHPoint(0.5)
            
            editFrame.size = editFrame.size.ratio(outerRatio, false)
            
            let frame = editFrame.frame
            var scale = CGFloat(1)
            
            // fix max scale
            Self.fixScale(&scale, anchor: anchor, frame: frame, angle: angle, bounds: self._bounds, accuracy: accuracy)
            
            if  scale < 1 {
                editFrame.size *= scale
            }
            
        } else {
            
            var vertical = false
            var size = Self._outerSize(for: editFrame.size, ratio: outerRatio, vertical: &vertical)
            
            Self._fit(size: &size, into: self._bounds, angle: angle, currentCenter: editFrame.center, staticAxis: vertical ? .vertical : .horizontal, accuracy: accuracy)
            
            // update size
            editFrame.size = size

            // fix position
            Self._fixPosition(&editFrame, bounds: self._bounds, along: vertical ? .horizontal : .vertical)
        }
        
        self._editFrame = editFrame
    }
    
    // MARK: - Private
    
    private func _resetPushScale()
    {
        self._pushScale = 1
    }
    
    private func _areClose(_ a: CGFloat, _ b: CGFloat, accuracy: CGFloat) -> Bool
    {
        abs(a - b) < accuracy
    }
    
    private func _isNotZero(_ a: CGPoint, accuracy: CGFloat) -> Bool
    {
        !self._areClose(a.x, 0, accuracy: accuracy) || !self._areClose(a.y, 0, accuracy: accuracy)
    }
    
    private func _updateFrame(_ scale: CGFloat, _ anchor: CGPoint)
    {
        var size = self._editFrame.size.scale(scale)
        
        // update min size
        if  let minSize = self._minSize, size.minSize < minSize {
            size = KHSize(minSize).ratio(size.ratio, false)
        }
        
        var point = size.point(at: anchor, relativeTo: .init(0.5))
        self._editFrame.needsRotation { angle in
            point = point.rotate(.zero, -angle)
        }
        let shift = point.scale(1 - scale)
        
        self._editFrame.center += shift
        self._editFrame.size = size
    }
}

extension KHCropRect.Editor /* static */
{
    fileprivate static func areClose(_ a: CGFloat, _ b: CGFloat, accuracy: CGFloat) -> Bool
    {
        abs(a - b) <= accuracy
    }
    
    fileprivate static func _isAngleCloseToZero(_ angle: CGFloat, accuracy: CGFloat) -> Bool
    {
        let angle = angle.truncatingRemainder(dividingBy: CGFloat.pi * 2)
        return self.areClose(angle, 0, accuracy: accuracy)
    }
    
    @discardableResult
    fileprivate static func fixScale(_ scale: inout CGFloat, anchor: CGPoint, frame: CGRect, angle: CGFloat, bounds: CGRect, accuracy: CGFloat) -> Bool
    {
        let targetPoint: CGPoint
        let targetFrame: CGRect
        
        if  self._isAngleCloseToZero(angle, accuracy: accuracy) {
            targetFrame = frame
            targetPoint = frame.point(at: anchor)
        } else {
            targetFrame = self.rotateFrameAroundCenter(frame, at: angle)
            targetPoint = frame.size.point(at: anchor, relativeTo: .init(0.5)).rotate(.zero, -angle) + targetFrame.center
        }
        
        let maxScale = self.maxScale(point: targetPoint, frame: targetFrame, bounds: bounds, accuracy: accuracy)
        
//        print("~~ scale: \(scale), maxScale \(maxScale)")
        
        guard let maxScale = maxScale, scale > maxScale else {
            return false
        }
        
        scale = maxScale
        
        return true
    }
    
    fileprivate static func maxScale(point: CGPoint, frame: CGRect, bounds: CGRect, accuracy: CGFloat) -> CGFloat?
    {
        let z = abs(accuracy)
        
        guard bounds.inset(.init(-z)).contains(point) else {
            return nil
        }
        
        var scale: CGFloat?
        
        self._updateScale(&scale, point.x - bounds.left, point.x - frame.left, accuracy: accuracy)
        self._updateScale(&scale, bounds.right - point.x, frame.right - point.x, accuracy: accuracy)
        self._updateScale(&scale, point.y - bounds.top, point.y - frame.top, accuracy: accuracy)
        self._updateScale(&scale, bounds.bottom - point.y, frame.bottom - point.y, accuracy: accuracy)
        
        return scale
    }
    
    fileprivate static func fixTranslation(_ translation: inout CGPoint, frame: CGRect, bounds: CGRect)
    {
        let inset = bounds.inset(for: frame)
        
        if  translation.x > 0 {
            translation.x = min(translation.x, inset.right)
        } else if translation.x < 0 {
            translation.x = max(translation.x, -inset.left)
        }
        
        if  translation.y > 0 {
            translation.y = min(translation.y, inset.bottom)
        } else if translation.y < 0 {
            translation.y = max(translation.y, -inset.top)
        }
    }
    
    fileprivate static func rotateFrameAroundCenter(_ frame: CGRect, at angle: CGFloat) -> CGRect
    {
        let center = frame.center
        let size = frame.applying(.init(rotationAngle: angle)).standardized.size
        let angledFrame = KHFrameCS(center, size)
        
        return angledFrame
    }
    
    private static func _updateScale(_ scale: inout CGFloat?, _ distanceToBounds: CGFloat, _ distanceToFrame: CGFloat, accuracy: CGFloat)
    {
        let z = abs(accuracy)
        
        guard distanceToBounds > z, distanceToFrame > z else {
            return
        }
        
        let sb = distanceToBounds / distanceToFrame
        if  let ss = scale {
            scale = min(ss, sb)
        } else {
            scale = sb
        }
    }
    
    private static func _fit(size inputSize: inout CGSize, into bounds: CGRect, angle: CGFloat, currentCenter: CGPoint, staticAxis: KHAxisGeometry.Axis, accuracy: CGFloat)
    {
        var size = inputSize
        let needsRotation = !Self._isAngleCloseToZero(angle, accuracy: accuracy)
        if  needsRotation {
            size = size.bounds.applying(.init(rotationAngle: angle)).standardized.size
        }
        
        var scale = CGFloat(1)
        
        // size scale fix
        
        KHAxisGeometry.enumerate { axis, horizontal, geometry, stop in
            
            let S = geometry.component(of: bounds.size)
            let s = geometry.component(of: size)
            
            if  s > S, s > 0 {
                scale = min(scale, S / s)
            }
        }
        
        // position scale fix
        
        var boundSize = bounds.size
        var center = currentCenter
        
        if  needsRotation {
            
            // get new rotated center and new rotated boundSize
            center = center.rotateInsideBox(&boundSize, angle)
            
            // rotate size back: this making even wider rect around it
            size = size.bounds.applying(.init(rotationAngle: -angle)).standardized.size
        }
        
        staticAxis.perform { axis, horizontal, geometry in
            
            let size = geometry.component(of: size)
            
            guard size > 0 else {
                return
            }
                
            let boundSize = geometry.component(of: boundSize)
            let center = geometry.component(of: center)
        
            let s = size / 2
            
            var d = center - 0
            if  d < s {
                scale = min(scale, d / s)
            } else {
                d = boundSize - center
                if  d < s {
                    scale = min(scale, d / s)
                }
            }
        }
        
        // update input size
        inputSize = inputSize.scale(scale)
    }
    
    private static func _fixSize(_ editFrame: inout EditFrame, bounds: CGRect, currentCenter: CGPoint, staticAxis: KHAxisGeometry.Axis)
    {
        var size = editFrame.rotatedSize()
        var scale = CGFloat(1)
        
        // size scale fix
        
        KHAxisGeometry.enumerate { axis, horizontal, geometry, stop in
            
            let S = geometry.component(of: bounds.size)
            let s = geometry.component(of: size)
            
            if  s > S, s > 0 {
                scale = min(scale, S / s)
            }
        }
        
        // position scale fix
        
        var boundSize = bounds.size
        var center = currentCenter
        
        editFrame.needsRotation { angle in
            
            // get new rotated center and new rotated boundSize
            center = center.rotateInsideBox(&boundSize, angle)
            
            // rotate size back: this making even wider rect around it
            size = EditFrame.rotateSize(size, by: -angle)
        }
        
        staticAxis.perform { axis, horizontal, geometry in
            
            let size = geometry.component(of: size)
            
            guard size > 0 else {
                return
            }
                
            let boundSize = geometry.component(of: boundSize)
            let center = geometry.component(of: center)
        
            let s = size / 2
            
            var d = center - 0
            if  d < s {
                scale = min(scale, d / s)
            } else {
                d = boundSize - center
                if  d < s {
                    scale = min(scale, d / s)
                }
            }
        }
        
        // update input size
        editFrame.size *= scale
    }
    
    private static func _fixSize(_ editFrame: inout EditFrame, bounds: CGRect)
    {
        let size = editFrame.rotatedSize()
        var scale = CGFloat(1)
        
        // size scale fix
        
        KHAxisGeometry.enumerate { axis, horizontal, geometry, stop in
            
            let S = geometry.component(of: bounds.size)
            let s = geometry.component(of: size)
            
            if  s > S, s > 0 {
                scale = min(scale, S / s)
            }
        }
        
        guard scale != 1 else {
            return
        }
        
        // update input size
        editFrame.size *= scale
    }
    
    private static func _fixPosition(_ inputFrame: inout CGRect, bounds: CGRect) -> [KHAxisGeometry.Axis]
    {
        var changed: [KHAxisGeometry.Axis] = []
        KHAxisGeometry.enumerate { axis, horizontal, geometry, stop in
            
            var frame = geometry.component(of: inputFrame)
            let bounds = geometry.component(of: bounds)
            
            if  frame.size > bounds.size {
                frame.start = bounds.start - (frame.size - bounds.size) / 2
            } else if frame.start < bounds.start {
                frame.start = bounds.start
            } else if frame.end > bounds.end {
                frame.end = bounds.end
            } else {
                return
            }
            
            geometry.update(&inputFrame, with: frame)
            changed.append(axis)
        }
        
        return changed
    }
    
    private static func _fixPosition(_ editFrame: inout EditFrame, bounds: CGRect)
    {
        var frame = editFrame.rotatedFrame()
        
        guard !self._fixPosition(&frame, bounds: bounds).isEmpty else {
            return
        }
        
        editFrame.center = frame.center
    }
    
    @discardableResult
    private static func _fixPosition(_ editFrame: inout EditFrame, bounds: CGRect, along baseAxis: KHAxisGeometry.Axis) -> Bool
    {
        let frame = editFrame.rotatedFrame()
        let angle = editFrame.angle
        
        var updatedFrame = frame
        let updatedAxes = self._put(frame: &updatedFrame, inside: bounds)
        
        var positionUpdate: CGFloat?
        for axis in updatedAxes {
            
            let coeff = axis == baseAxis ? cos(angle) : sin(angle)
            guard coeff != 0 else {
                continue
            }
            
            let delta = axis.geometry.component(of: updatedFrame.origin) - axis.geometry.component(of: frame.origin)
            
            let shift = delta / coeff
            
            if  let a = positionUpdate {
                let b = shift
                
                // check previous update:
                // [1] if new one and old are in the same direction, get maximum of them
                // [2] otherwise sum them, since we don't know which one is priority
                
                if  a >= 0 && b >= 0 {
                    positionUpdate = max(a, b)
                } else if a < 0 && b < 0 {
                    positionUpdate = min(a, b)
                } else {
                    positionUpdate = a + b
                }
            } else {
                positionUpdate = shift
            }
        }
        
        guard let positionUpdate = positionUpdate else {
            return false
        }
        
        baseAxis.geometry.update(&editFrame.center) { component in
            component += positionUpdate
        }
        return true
    }
    
    private static func _put(frame inputFrame: inout CGRect, inside bounds: CGRect) -> [KHAxisGeometry.Axis]
    {
        var changed: [KHAxisGeometry.Axis] = []
        KHAxisGeometry.enumerate { axis, horizontal, geometry, stop in
            
            var frame = geometry.component(of: inputFrame)
            let bounds = geometry.component(of: bounds)
            
            if  frame.size > bounds.size {
                frame.start = bounds.start - (frame.size - bounds.size) / 2
            } else if frame.start < bounds.start {
                frame.start = bounds.start
            } else if frame.end > bounds.end {
                frame.end = bounds.end
            } else {
                return
            }
            
            geometry.update(&inputFrame, with: frame)
            changed.append(axis)
        }
        
        return changed
    }
    
    private static func _put(frame inputFrame: inout CGRect, inside bounds: CGRect, angle: CGFloat, accuracy: CGFloat)
    {
        var frame = inputFrame
        
        if !Self._isAngleCloseToZero(angle, accuracy: accuracy) {
            frame = self.rotateFrameAroundCenter(frame, at: angle)
        }
        
        var updatedFrame = frame
        let updatedAxes = self._put(frame: &updatedFrame, inside: bounds)
        
        guard !updatedAxes.isEmpty else {
            return
        }
        
        let delta = (updatedFrame.center - inputFrame.center).rotate(.zero, -angle)
        inputFrame.origin += delta
    }
    
    @discardableResult
    private static func _put(frame inputFrame: inout CGRect, inside bounds: CGRect, angle: CGFloat, along baseAxis: KHAxisGeometry.Axis, accuracy: CGFloat) -> Bool
    {
        var frame = inputFrame
        
        if !self._isAngleCloseToZero(angle, accuracy: accuracy) {
            frame = self.rotateFrameAroundCenter(frame, at: angle)
        }
        
        var updatedFrame = frame
        let updatedAxes = self._put(frame: &updatedFrame, inside: bounds)
        
        var positionUpdate: CGFloat?
        for axis in updatedAxes {
            
            let coeff = axis == baseAxis ? cos(angle) : sin(angle)
            guard coeff != 0 else {
                continue
            }
            
            let delta = axis.geometry.component(of: updatedFrame.origin) - axis.geometry.component(of: frame.origin)
            
            let shift = delta / coeff
            
            if  let a = positionUpdate {
                let b = shift
                
                // check previous update:
                // [1] if new one and old are in the same direction, get maximum of them
                // [2] otherwise sum them, since we don't know which one is priority
                
                if  a >= 0 && b >= 0 {
                    positionUpdate = max(a, b)
                } else if a < 0 && b < 0 {
                    positionUpdate = min(a, b)
                } else {
                    positionUpdate = a + b
                }
            } else {
                positionUpdate = shift
            }
        }
        
        guard let positionUpdate = positionUpdate else {
            return false
        }
        
        baseAxis.geometry.update(&inputFrame.origin) { component in
            component += positionUpdate
        }
        return true
    }
    
    private static func _fixMinScale(_ scale: CGFloat, _ size: CGSize, _ minSize: CGFloat) -> CGFloat
    {
        var scale = scale
        
        // fix min scale
        if  size.width * scale < minSize || size.height * scale < minSize {
            scale = max(KHRatio(minSize, size.width), KHRatio(minSize, size.height))
        }
        
        return scale
    }
    
    private static func _outerSize(for size: CGSize, ratio: CGFloat, vertical: inout Bool) -> CGSize
    {
        guard ratio != 0, size.height != 0 else {
            return size
        }

        var newSize = KHSize(0)
        vertical = ratio > size.ratio
        
        if  vertical {
            newSize.width  = size.height * ratio
            newSize.height = size.height
        } else {
            newSize.width  = size.width
            newSize.height = size.width  / ratio
        }
        
        return newSize
    }
}



// *************************
// *************************  Class Methods
// *************************



extension KHCropRect.Editor
{
    /*!
     cropRotation - angle in radians used for crop rect
     userRotation - visible angle in degrees, used for UI
     */
    static public func userRotation(from cropRotation: CGFloat) -> CGFloat
    {
        cropRotation / CGFloat.pi * 180.0
    }
    
    static public func cropRotation(from userRotation: CGFloat) -> CGFloat
    {
        userRotation / 180.0 * CGFloat.pi
    }
}
