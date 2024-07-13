//
//  KHController.swift
//  kh-kit
//
//  Created by Alex Khuala on 18.06.22.
//

import UIKit

class KHController<LayoutView: KHLayoutView>: UIViewController
{
    var layoutView: LayoutView {
        return self.view as! LayoutView
    }
    
    override func loadView() {
        self.view = LayoutView()
    }
}
