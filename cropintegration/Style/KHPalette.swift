//
//  KHPalette.swift
//  printer
//
//  Created by Alex Khuala on 10.06.22.
//

import UIKit

struct KHPalette
{
    typealias T = KHColor
    
    let main: T
    let back: T
    let bar: T
    let active: T
    let passive: T
    let canvas: T
    let cropContentBorder: T
    let cropLineMain: T
    let cropLineNext: T
    let text: T
    let cropSlider: T
    let button: T
    let buttonBack: T
            
    init(_ name: KHTheme.Name) { switch name {
    case .gray:
        
        main = .init(222, 223, 225)
        back = .init(30, 32, 36)
        bar = .init(40, 42, 46)
        canvas = .init(52, 54, 58)
        active = .init(255, 192, 87)
        passive = .init(108, 108, 110)
        cropContentBorder = .init(128)
        cropLineMain = .init(255, 0.5)
        cropLineNext = .init(0, 0.3)
        cropSlider = .init(255, 0.8)
        
        text = main
        button = .white
        buttonBack = .init(28, 86, 149)
    }}
}
