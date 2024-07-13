//
//  KHEventTransparentView.swift
//  cropintegration
//
//  Created by Alex Khuala on 14.02.23.
//

import UIKit

class KHEventTransparentView: KHView
{
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        for subview in self.subviews {
            let inPoint = self.convert(point, to: subview)
            if  subview.point(inside: inPoint, with: event) {
                return true
            }
        }
        
        return false
    }
}
