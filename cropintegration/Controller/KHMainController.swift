//
//  KHMainController.swift
//  cropintegration
//
//  Created by Alex Khuala on 29.03.24.
//

import UIKit

class KHMainController: KHController<KHMainLayoutView>
{
    init(with viewModel: KHMainView_ViewModel)
    {
        self._viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        self.unregisterForThemeUpdates()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.layoutView.setView(KHZoomScrollView(with: KHMainViewContentProvider(with: self._viewModel, delegate: self)), for: .content)
        self.layoutView.setView(KHMainTopBar(), for: .topBar)
        self.layoutView.setView(KHMainBottomBar(with: self), for: .bottomBar)
        
        self.registerForThemeUpdates()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    // MARK: - Private
    
    private let _viewModel: KHMainView_ViewModel
}

extension KHMainController: KHTheme_Sensitive
{
    typealias Theme = KHTheme
    
    func didChangeTheme()
    {
        self.layoutView.updateColors()
    }
}


extension KHMainController: KHMainView_Delegate
{
    func mainViewDidRequestEditPhoto(_ view: any KHEditViewModel_Delegate) 
    {
        let controller = KHEditController(with: KHEditViewModel(delegate: view), delegate: self)
        
        controller.willMove(toParent: self)
        self.addChild(controller)
        self.view.addSubview(controller.view)
        controller.didMove(toParent: self)
        
        controller.view.frame = self.view.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.show()
    }
}

extension KHMainController: KHEditController_Delegate
{
    func editControllerDidFinish(controller: KHEditController, cancelled: Bool)
    {
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        controller.didMove(toParent: nil)
    }
}

extension KHMainController: KHMainBottomBar_Delegate
{
    func bottomBarDidTapCropButton(_ bottomBar: KHMainBottomBar) 
    {
        self._viewModel.listeners.notify { listener in
            listener.didRequestCrop()
        }
    }
}
