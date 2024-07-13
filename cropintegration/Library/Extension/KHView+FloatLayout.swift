//
//  KHFloatLayout.swift
//  kh-kit
//
//  Created by Alex Khuala on 22.01.24.
//

import UIKit

enum KHViewFloatLayoutSpacing
{
    case constant(_ value: CGFloat)
    case minimum(_ value: CGFloat) // occupy all free space > value
    
    var minValue: CGFloat {
        switch self {
        case .constant(let value):  value
        case .minimum(let value):   value
        }
    }
}

struct KHViewFloatLayoutEntry
{
    let identifier: Int
    let view: KHView
    let minWidth: CGFloat
    var stretchable: Bool = false
    var spacingLeft: KHViewFloatLayoutSpacing = .constant(0)
    
    // the higher priority, the earlier preferredWidth is used
    var preferredWidth: CGFloat?
    var preferredWidthPriority: Int = 0
}

protocol KHViewFloatLayout_Entries
{
    func enumerate(in block: (_ entry: KHViewFloatLayoutEntry) -> Void)
}

extension KHView
{
    /*!
     
     When rewriting updateFrameBlock do not forget to apply new frame to the view
     
     */
    func floatLayout(entries: KHViewFloatLayout_Entries, contentInset: UIEdgeInsets = .zero, options: LayoutOptions = [], updateFrameBlock: (_ identifier: Int, _ view: KHView, _ frame: CGRect) -> Void = { i, v, f in v.frame = f.pixelRound() })
    {
        let padding = contentInset
        var bounds  = self.bounds.inset(padding)
        
        // layout subviews
        var items: [LayoutItem] = []
        var width: CGFloat = 0
        var preferredWidth: CGFloat = 0
        var spacing: CGFloat = 0
        var stretchableSpacingCount: Int = 0
        var stretchableWidthCount: Int = 0
        var preferredDeltaPerPrio: [Int: CGFloat] = [:]
        
        // 1st iteration: collect group view data
        var first: Bool = true
        entries.enumerate { entry in
            
            let minWidth = entry.minWidth
            if  entry.stretchable {
                stretchableWidthCount += 1
            }
            
            if  let w = entry.preferredWidth {
                let k = entry.preferredWidthPriority
                preferredWidth += w
                preferredDeltaPerPrio[k] = (preferredDeltaPerPrio[k] ?? 0) + max(0, w - minWidth)
            } else {
                preferredWidth += minWidth
            }
            
            var stretchableSpacing = false
            let spacingLeft: CGFloat
            
            if  first {
                first = false
                spacingLeft = 0
            } else {
                switch entry.spacingLeft {
                case .constant(let v):
                    spacingLeft = v
                    spacing += v
                case .minimum(let v):
                    spacingLeft = v
                    spacing += v
                    stretchableSpacingCount += 1
                    stretchableSpacing = true
                }
            }

            items.append(.init(entry.identifier, entry.view, minWidth, entry.stretchable, spacingLeft, stretchableSpacing, entry.preferredWidth, entry.preferredWidthPriority))
            width += minWidth
        }
        
        guard items.count > 0 else {
            return
        }
        
        let sorterDeltaPerPrio = preferredDeltaPerPrio.sorted { $0.key > $1.key }
        let minPreferredPriority: Int
        
        var widthDelta: CGFloat = 0
        var spacingDelta: CGFloat = 0
        
        // 1.5 iteration: update parent width or delta/clearance
        if  options.contains(.sizeToFitWidth) {
            
            bounds.width = width + spacing
            self.width = bounds.right + padding.right
            
            minPreferredPriority = sorterDeltaPerPrio.last?.key ?? 0
            
        } else {
            
            let W = bounds.width - preferredWidth - spacing
            if  W >= 0 {
                
                minPreferredPriority = sorterDeltaPerPrio.last?.key ?? 0
                
                if  stretchableSpacingCount > 0 {
                    spacingDelta = W / CGFloat(stretchableSpacingCount)
                } else if stretchableWidthCount > 0 {
                    widthDelta = W / CGFloat(stretchableWidthCount)
                }
                
            } else {
                
                var p = (sorterDeltaPerPrio.first?.key ?? 0) + 1
                var w = bounds.width - width - spacing
                if  w >= 0 {
                    
                    for (priority, delta) in sorterDeltaPerPrio {
                        
                        let nw = w - delta
                        guard nw >= 0 else {
                            break
                        }
                        
                        w = nw
                        p = priority
                    }
                    
                    if  stretchableSpacingCount > 0 {
                        spacingDelta = w / CGFloat(stretchableSpacingCount)
                    } else if stretchableWidthCount > 0 {
                        widthDelta = w / CGFloat(stretchableWidthCount)
                    }
                    
                } else {
                    
                    if  stretchableWidthCount > 0 {
                        widthDelta = w / CGFloat(stretchableWidthCount)
                    }
                }
                
                minPreferredPriority = p
            }
        }
        
        // 2nd iteration: set new size, calculate height
        var height: CGFloat = 0
        for item in items {
            let view  = item.view
            var width = item.width
            if  let pw = item.preferredWidth, item.preferredWidthPriority >= minPreferredPriority, pw > width {
                width = pw
            }
            
            view.width = width + (item.stretchable ? widthDelta : 0)
            view.forceLayout(options: .sizeToFitHeight)
            height = max(height, view.height)
        }
        
        // 2.5 iteration set bounds if needed
        if  options.contains(.sizeToFitHeight) {
            
            bounds.height = height
            self.height = bounds.bottom + padding.bottom
            
        }
                
        // 3nd iteration: set items frame
        var inset = KHInset(0)
        for item in items {
            
            let spacingLeft = item.spacingLeft + (item.stretchableSpacing ? spacingDelta : 0)
            let frame = bounds.inframe(item.view.size, .left, inset.adjust(left: spacingLeft))
            updateFrameBlock(item.identifier, item.view, frame)
            inset.left = frame.right - bounds.left
        }
    }
    
    private struct LayoutItem
    {
        let view: KHView
        let identifier: Int
        let width: CGFloat
        let stretchable: Bool
        let spacingLeft: CGFloat
        let stretchableSpacing: Bool
        let preferredWidth: CGFloat?
        let preferredWidthPriority: Int
        
        init(_ identifier: Int, _ view: KHView, _ width: CGFloat, _ stretchable: Bool, _ spacingLeft: CGFloat, _ stretchableSpacing: Bool, _ preferredWidth: CGFloat?, _ preferredWidthPriority: Int)
        {
            self.view = view
            self.identifier = identifier
            self.width = width
            self.stretchable = stretchable
            self.spacingLeft = spacingLeft
            self.stretchableSpacing = stretchableSpacing
            self.preferredWidth = preferredWidth
            self.preferredWidthPriority = preferredWidthPriority
        }
    }
}

