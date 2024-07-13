//
//  KHOrientation2.swift
//  kh-kit
//
//  Created by Alex Khuala on 29.04.23.
//

import UIKit

public struct KHOrientation2: Hashable, Equatable, Codable
{
    public init(rotation: Int = 0)
    {
        self.rotation = rotation
    }
    
    public init(_ imageOrientation: UIImage.Orientation)
    {
        if  let index = Self._orientations.firstIndex(of: imageOrientation) {
            self.flippedX = index % 2 != 0
            self.rotation = index / 2
        }
    }
    
    public init(_ transform: CGAffineTransform)
    {
        let angle = atan2(transform.b, transform.d)
        let rotation: Int = Int(round(2 * Double(angle) / .pi))
        
        let transformWithoutRotation = transform.concatenating(CGAffineTransform(rotationAngle: -angle))
        
        let sx = transformWithoutRotation.a
        let sy = transformWithoutRotation.d
        
        let flippedX = sx < 0
        let flippedY = sy < 0
        
        self.flippedX = flippedX
        self.flippedY = flippedY
        self.rotation = rotation
    }
    
    fileprivate init(rotation: Int, flippedX: Bool, flippedY: Bool = false)
    {
        self.rotation = rotation
        self.flippedX = flippedX
        self.flippedY = flippedY
    }
    
    public static let normal = KHOrientation2()
        
    public private(set) var flippedX: Bool = false
    public private(set) var flippedY: Bool = false
    public private(set) var rotation: Int  = 0
    
    // MARK: - Public
    
    public var imageOrientation: UIImage.Orientation {
        
        let orientation = self.simplify()
        let index = orientation.rotation * 2 + (orientation.flippedX ? 1 : 0)

        return Self._orientations[index]
    }
    
    public var transform: CGAffineTransform {
        
        let transform = CGAffineTransform(rotationAngle: self.rotationAngle)
        let flipScale = self.flipScale

        return transform.scaledBy(x: flipScale.x, y: flipScale.y)
    }
    
    public var rotationAngle: CGFloat {
        return CGFloat(self.rotation) * CGFloat.pi / 2
    }
    
    public var flipScale: CGPoint {
        return KHPoint(self.flippedX ? -1 : 1, self.flippedY ? -1 : 1)
    }
    
    public var exifOrientation: Int {
        switch (self.imageOrientation) {
            case .down:             return 3
            case .left:             return 8
            case .right:            return 6
            case .upMirrored:       return 2
            case .downMirrored:     return 4
            case .leftMirrored:     return 5
            case .rightMirrored:    return 7
            case .up:               fallthrough
            default:                return 1
        }
    }
    
    public var rotated: Bool
    {
        self.rotation % 2 != 0
    }
    
    public var flipped: Bool
    {
        return self.flippedX != self.flippedY
    }
    
    public var empty: Bool
    {
        guard self.flippedX, self.flippedY else {
            return !self.flipped && self.rotation % Self._rotationBase == 0
        }
        return abs(self.rotation % Self._rotationBase) == 2
    }
    
    mutating func prependOrientation(_ orientation: KHOrientation2)
    {
        var new = orientation
        new.appendOrientation(self)
        
        self = new
    }
    
    mutating func appendOrientation(_ orientation: KHOrientation2)
    {
        let selfRotated = self.rotated
        
        let flippedX = selfRotated ? orientation.flippedY : orientation.flippedX
        let flippedY = selfRotated ? orientation.flippedX : orientation.flippedY
        
        if (flippedX) {
            self.flippedX = !self.flippedX
        }
        if (flippedY) {
            self.flippedY = !self.flippedY
        }
        
        self.rotation += orientation.rotation
    }
    
    public var inverseOrientation: Self
    {
        let rotated = self.rotated
        
        var orientation = Self()
        orientation.flippedX = rotated ? self.flippedY : self.flippedX
        orientation.flippedY = rotated ? self.flippedX : self.flippedY
        orientation.rotation = -self.rotation
        
        return orientation
    }
    
    /*!
     @brief Make flippedY always false and angle in range 0...3
     */
    func simplify() -> Self
    {
        var rotation = self.rotation
        var flippedX = self.flippedX
        
        if  self.flippedY {
            flippedX.toggle()
            rotation += 2
        }
        
        let base = Self._rotationBase
        switch rotation {
        case ..<0:
            rotation = rotation % base + base
        case base...:
            rotation = rotation % base
        default:
            break
        }
        
        return .init(rotation: rotation, flippedX: flippedX)
    }
    
    /*!
     @brief Makes nil when simplified orientation is empty
     */
    func nullify(_ condition: Bool = true) -> Self?
    {
        return condition && self.empty ? nil : self
    }
    
    // MARK: - Internal
    
    private static let _rotationBase: Int = 4
    
    private static let _orientations: [UIImage.Orientation] = [.up, .upMirrored, .right, .rightMirrored, .down, .downMirrored, .left, .leftMirrored]
}



// *************************
// *************************
// *************************


public extension KHOrientation2
{
    class Editor
    {
        init(with orientation: KHOrientation2?)
        {
            guard orientation != nil else {
                return
            }
            self._update(from: orientation!)
        }
        
        var orientation: KHOrientation2
        {
            get {
                .init(rotation: self._rotation, flippedX: self._flippedX, flippedY: self._flippedY)
            }
            set {
                self._update(from: newValue)
            }
        }
        
        // MARK: - Actions
        
        func flip(vertically: Bool)
        {
            self._rotated == vertically ? self._flippedX.toggle() : self._flippedY.toggle()
        }

        func rotate(clockwise: Bool)
        {
            self._rotation += clockwise ? 1 : -1
        }
        
        func reset(keepingRotation: Bool)
        {
            self._flippedX = false
            self._flippedY = false
            if !keepingRotation {
                self._rotation = 0
            }
        }
        
        // MARK: - Private
        
        private var _flippedX: Bool = false
        private var _flippedY: Bool = false
        private var _rotation: Int = 0
        
        private var _rotated: Bool {
            self._rotation % 2 != 0
        }
        
        private func _update(from orientation: KHOrientation2)
        {
            self._flippedX = orientation.flippedX
            self._flippedY = orientation.flippedY
            self._rotation = orientation.rotation
        }
    }
}
