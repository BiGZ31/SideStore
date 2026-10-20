//
//  TabBarController.swift
//  AltStore
//
//  Created by Riley Testut on 9/19/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

@preconcurrency import UIKit

extension TabBarController
{
    private enum Tab: Int, CaseIterable
    {
        case news
        case sources
        case browse
        case myApps
        case settings
    }
}

final class TabBarController: UITabBarController
{
    private var initialSegue: (identifier: String, sender: Any?)?
    
    private var _viewDidAppear = false
    
    private var sourcesViewController: SourcesViewController!
    // fucksubs: index-independent refs so hiding the News tab can't break navigation.
    private weak var sourcesNav: UIViewController?
    private weak var browseNav: UIViewController?
    private weak var myAppsNav: UIViewController?
    private weak var settingsNav: UIViewController?

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.importApp(_:)), name: AppDelegate.importAppDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.presentSources(_:)), name: AppDelegate.addSourceDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.openErrorLog(_:)), name: ToastView.openErrorLogNotification, object: nil)
    }
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()
        debugLog("[TabBarController] viewDidLoad()")
        
        let browseNavigationController = self.viewControllers![Tab.browse.rawValue] as! UINavigationController
        browseNavigationController.tabBarItem.image = UIImage(systemName: "bag")
        
        let sourcesNavigationController = self.viewControllers![Tab.sources.rawValue] as! UINavigationController
        self.sourcesViewController = sourcesNavigationController.viewControllers.first as? SourcesViewController

        // fucksubs: keep references, hide the News tab, and open on Browse (our apps).
        self.sourcesNav = sourcesNavigationController
        self.browseNav = browseNavigationController
        self.myAppsNav = self.viewControllers?[Tab.myApps.rawValue]
        self.settingsNav = self.viewControllers?[Tab.settings.rawValue]
        let newsNav = self.viewControllers?[Tab.news.rawValue]
        if var vcs = self.viewControllers, let news = newsNav {
            vcs.removeAll { $0 === news }
            self.viewControllers = vcs
        }
        if let i = self.viewControllers?.firstIndex(where: { $0 === browseNavigationController }) {
            self.selectedIndex = i
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        debugLog("[TabBarController] viewDidAppear() — TabBarController is now visible")
        
        _viewDidAppear = true
        
        if let (identifier, sender) = self.initialSegue
        {
            self.initialSegue = nil
            self.performSegue(withIdentifier: identifier, sender: sender)
        }
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?)
    {
        guard _viewDidAppear else {
            self.initialSegue = (identifier, sender)
            return
        }
        
        super.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension TabBarController
{
    @objc func presentSources(_ sender: Any)
    {
        if let presentedViewController = self.presentedViewController
        {
            presentedViewController.dismiss(animated: true) {
                self.presentSources(sender)
            }
            
            return
        }
                
        if let notification = (sender as? Notification), let sourceURL = notification.userInfo?[AppDelegate.addSourceDeepLinkURLKey] as? URL
        {
            self.sourcesViewController?.deepLinkSourceURL = sourceURL
        }
        
        self.select(self.sourcesNav)
    }
}

private extension TabBarController
{
    // fucksubs: select a tab by reference, so indices can change (News hidden) safely.
    func select(_ vc: UIViewController?)
    {
        guard let vc = vc, let i = self.viewControllers?.firstIndex(where: { $0 === vc }) else { return }
        self.selectedIndex = i
    }

    @objc func importApp(_ notification: Notification)
    {
        self.select(self.myAppsNav)
    }

    @objc func openErrorLog(_ notification: Notification)
    {
        self.select(self.settingsNav)
    }
}
