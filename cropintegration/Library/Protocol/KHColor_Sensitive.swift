//
//  KHColor_Sensitive.swift
//  cropintegration
//
//  Created by Alex Khuala on 28.07.23.
//

import UIKit

protocol KHColor_Sensitive
{
    func updateColors()
}

class KHColorSensitiveTools
{
    @discardableResult
    static func updateColors(of view: UIView?) -> Bool
    {
        guard let view = view as? KHColor_Sensitive else {
            return false
        }
        view.updateColors()
        return true
    }
}
