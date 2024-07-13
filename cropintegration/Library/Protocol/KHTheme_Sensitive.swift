//
//  KHTheme_Sensitive.swift
//  cropintegration
//
//  Created by Alex Khuala on 30.04.23.
//

import UIKit

protocol KHTheme_Protocol
{
    static func addListener(_ listener: any KHTheme_Sensitive)
    static func removeListener(_ listener: any KHTheme_Sensitive)
}

protocol KHTheme_Sensitive<Theme>: AnyObject
{
    associatedtype Theme: KHTheme_Protocol
    
    func didChangeTheme()
}

extension KHTheme_Sensitive
{
    func registerForThemeUpdates(triggerUpdate: Bool = true)
    {
        Theme.addListener(self)
        self.didChangeTheme()
    }
    
    func unregisterForThemeUpdates()
    {
        Theme.removeListener(self)
    }
}
