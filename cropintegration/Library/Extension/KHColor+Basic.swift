//
//  KHColor.swift
//  kh-kit
//
//  Created by Alex Khuala on 3/6/18.
//  Copyright © 2018 Alex Khuala. All rights reserved.
//

import UIKit

public typealias KHColor = UIColor
public extension KHColor
{
    convenience init(_ red: UInt8, _ green: UInt8, _ blue: UInt8, _ alpha: CGFloat = 1) {
        
        let M: CGFloat = 255;
        let R: CGFloat = CGFloat(red)   / M
        let G: CGFloat = CGFloat(green) / M
        let B: CGFloat = CGFloat(blue)  / M
        
        self.init(red: R, green: G, blue: B, alpha: alpha)
    }
    
    convenience init(_ gray: UInt8, _ alpha: CGFloat = 1) {
        
        let M: CGFloat = 255
        let W: CGFloat = CGFloat(gray) / M
        
        self.init(white: W, alpha: alpha)
    }
    
    convenience init(_ hexColor: String)
    {
        var rgbValue: UInt64 = 0
        let scanner = Scanner(string: hexColor)
        
        if  hexColor.first == "#" {
            scanner.currentIndex = scanner.string.index(scanner.currentIndex, offsetBy: 1)
        }
        
        if  scanner.scanHexInt64(&rgbValue) {
            self.init(UInt8((rgbValue & 0xFF0000) >> 16), UInt8((rgbValue & 0xFF00) >> 8), UInt8(rgbValue & 0xFF))
        } else {
            self.init(255)
        }
    }
    
    convenience init(_ cgColor: CGColor)
    {
        self.init(cgColor: cgColor)
    }
    
    var hexColor: String {
        
        func componentFromRelative(_ rel: CGFloat) -> UInt8 {
            return UInt8(fmax(0, fmin(255, (rel * 255.0).round())))
        }
        
        var str = "ffffff";
        var red   : CGFloat = 0;
        var green : CGFloat = 0;
        var blue  : CGFloat = 0;
        
        if (self.getRed(&red, green: &green, blue: &blue, alpha: nil)) {
            
            let R = componentFromRelative(red)
            let G = componentFromRelative(green)
            let B = componentFromRelative(blue)
            
            str = String(format: "%02x%02x%02x", R, G, B)
        }
        
        return str
    }
    
    var luminance: CGFloat {
        
        var red   : CGFloat = 0
        var green : CGFloat = 0
        var blue  : CGFloat = 0
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: nil) else {
            return 0
        }
        
        return red * 0.299 + green * 0.587 + blue * 0.114
    }
    
    func needsBorder(on backgroundColor: UIColor, threshold: CGFloat = 1.5) -> Bool
    {
        let a = self.luminance
        let b = backgroundColor.luminance
        
        // Calculate the contrast ratio
        let contrastRatio = (max(a, b) + 0.05) / (min(a, b) + 0.05)
        
        // Check if the contrast ratio meets the threshold for readability
        return contrastRatio < threshold
    }
    
    func isLight() -> Bool
    {
        self.luminance > 0.65
    }
    
    /**
     Create a ligher color
     */
    func lighter(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjustBrightness(by: abs(percentage))
    }
    
    /**
     Create a darker color
     */
    func darker(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjustBrightness(by: -abs(percentage))
    }
    
    /**
     Try to increase brightness or decrease saturation
     */
    func adjustBrightness(by percentage: CGFloat = 30.0) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            if b < 1.0 {
                let newB: CGFloat = max(min(b + (percentage/100.0)*b, 1.0), 0.0)
                return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
            } else {
                let newS: CGFloat = min(max(s - (percentage/100.0)*s, 0.0), 1.0)
                return UIColor(hue: h, saturation: newS, brightness: b, alpha: a)
            }
        }
        return self
    }
}
