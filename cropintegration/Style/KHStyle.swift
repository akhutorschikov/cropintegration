//
//  KHStyle.swift
//  cropintegration
//
//  Created by Alex Khuala on 29.03.24.
//

import UIKit

struct KHStyle 
{
    // MARK: - Font

    static let digitFont: UIFont = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
    static let mainFont: UIFont = .systemFont(ofSize: 13)
    static let listFont: UIFont = .systemFont(ofSize: 46)
    static let listSmallFont: UIFont = .systemFont(ofSize: 35)
    static let headerFont: UIFont = .systemFont(ofSize: 18, weight: .medium)
    static let buttonFont: UIFont = .systemFont(ofSize: 18, weight: .medium)
    
    // MARK: - Size
    
    static let buttonSize: CGSize = .init(80, 32)
    static let cropButtonSize: CGSize = .init(246, 50)
    static let minListRowHeight: CGFloat = 150
    
    // MARK: - Inset
    
    static let barVerticalInset: CGFloat = 14
    static let mainInset: CGFloat = 20
    static let toastPadding: UIEdgeInsets = .init(x: 6, y: 4)
    static let buttonGroupInset: UIEdgeInsets = .init(x: 10)
    static let listInset: UIEdgeInsets = .init(left: 100, right: 72)
    
    // MARK: - Spacing
    
    static let buttonGroupSpacing: CGFloat = 16
    
    // MARK: - Value

    static let cornerRadius: CGFloat = 4
}
