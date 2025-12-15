//
//  MainTabBarController.swift
//  Fitly
//
//  Created by Bakdaulet Yeskermes on 23.10.2025.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTabs()
        setupTabBarAppearance()
    }

    private func setupTabs() {
        let main = MainViewController()
        main.tabBarItem = UITabBarItem(title: "Main", image: UIImage(systemName: "house"), tag: 0)
        
        let history = HistoryViewController()
        history.tabBarItem = UITabBarItem(title: "History", image: UIImage(systemName: "clock"), tag: 1)
        
        let search = SearchViewController()
        let searchNav = UINavigationController(rootViewController: search)
        searchNav.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 2)

        let profile = ProfileViewController()
        profile.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), tag: 3)

        viewControllers = [main, searchNav, history, profile]
    }

    private func setupTabBarAppearance() {
        tabBar.tintColor = .app
    }
}
