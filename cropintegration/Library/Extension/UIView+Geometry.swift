//
//  UIView+EasyFrame.swift
//  kh-kit
//
//  Created by Alex Khuala on 2/4/18.
//  Copyright © 2018 Alex Khuala. All rights reserved.
//

import UIKit

public extension UIView
{
    convenience init(_ frame: CGRect)
    {
        self.init(frame: frame);
    }
    
    var size: CGSize
    {
        set {
            self.frame.size = newValue;
        }
        get {
            return self.frame.size;
        }
    }
    
    var origin: CGPoint
    {
        set {
            self.frame.origin = newValue;
        }
        get {
            return self.frame.origin;
        }
    }
    
    var width: CGFloat
    {
        set {
            self.frame.width = newValue;
        }
        get {
            return self.frame.width;
        }
    }
    
    var height: CGFloat
    {
        set {
            self.frame.height = newValue;
        }
        get {
            return self.frame.height;
        }
    }
    
    var left: CGFloat
    {
        set {
            self.frame.left = newValue;
        }
        get {
            return self.frame.left;
        }
    }
    
    var right: CGFloat
    {
        set {
            self.frame.right = newValue;
        }
        get {
            return self.frame.right;
        }
    }
    
    var top: CGFloat
    {
        set {
            self.frame.top = newValue;
        }
        get {
            return self.frame.top;
        }
    }
    
    var bottom: CGFloat
    {
        set {
            self.frame.bottom = newValue;
        }
        get {
            return self.frame.bottom;
        }
    }
    
    var end: CGPoint
    {
        get {
            self.frame.end
        }
        set {
            self.frame.end = newValue
        }
    }
    
    var leftInverted: CGFloat
    {
        set {
            self.left = (self.superview?.bounds.width ?? 0) - newValue;
        }
        get {
            return (self.superview?.bounds.width ?? 0) - self.left;
        }
    }
    
    var rightInverted: CGFloat
    {
        set {
            self.right = (self.superview?.bounds.width ?? 0) - newValue;
        }
        get {
            return (self.superview?.bounds.width ?? 0) - self.right;
        }
    }
    
    var topInverted: CGFloat
    {
        set {
            self.top = (self.superview?.bounds.height ?? 0) - newValue;
        }
        get {
            return (self.superview?.bounds.height ?? 0) - self.top;
        }
    }
    
    var bottomInverted: CGFloat
    {
        set {
            self.bottom = (self.superview?.bounds.height ?? 0) - newValue;
        }
        get {
            return (self.superview?.bounds.height ?? 0) - self.bottom;
        }
    }
}
