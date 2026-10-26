//
//  HomeTabBarController.swift
//  SwiftHub
//
//  Created by Khoren Markosyan on 1/5/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import UIKit
import RxSwift

enum HomeTabBarItem: Int {
    case search, news, notifications, settings, login

    private func controller(with viewModel: ViewModel, navigator: Navigator) -> UIViewController {
        switch self {
        case .search:
            let vc = SearchViewController(viewModel: viewModel, navigator: navigator)
            return NavigationController(rootViewController: vc)
        case .news:
            let vc = EventsViewController(viewModel: viewModel, navigator: navigator)
            return NavigationController(rootViewController: vc)
        case .notifications:
            let vc = NotificationsViewController(viewModel: viewModel, navigator: navigator)
            return NavigationController(rootViewController: vc)
        case .settings:
            let vc = SettingsViewController(viewModel: viewModel, navigator: navigator)
            return NavigationController(rootViewController: vc)
        case .login:
            let vc = LoginViewController(viewModel: viewModel, navigator: navigator)
            return NavigationController(rootViewController: vc)
        }
    }

    /// 图标改用 SF Symbols，与官方客户端一致（house / bell / magnifyingglass / person）
    private func symbol(_ name: String) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        return UIImage(systemName: name, withConfiguration: config)
    }

    var image: UIImage? {
        switch self {
        case .search: return symbol("magnifyingglass")
        case .news: return symbol("house")
        case .notifications: return symbol("bell")
        case .settings: return symbol("person.crop.circle")
        case .login: return symbol("person.crop.circle.badge.plus")
        }
    }

    var selectedImage: UIImage? {
        switch self {
        case .search: return symbol("magnifyingglass")
        case .news: return symbol("house.fill")
        case .notifications: return symbol("bell.fill")
        case .settings: return symbol("person.crop.circle.fill")
        case .login: return symbol("person.crop.circle.badge.plus")
        }
    }

    /// 文案对齐官方：Home / Notifications / Explore / Profile
    var title: String {
        switch self {
        case .search: return L(.homeTabBarExploreTitle)
        case .news: return L(.homeTabBarHomeTitle)
        case .notifications: return L(.homeTabBarNotificationsTitle)
        case .settings: return L(.homeTabBarProfileTitle)
        case .login: return L(.homeTabBarSignInTitle)
        }
    }

    func getController(with viewModel: ViewModel, navigator: Navigator) -> UIViewController {
        let vc = controller(with: viewModel, navigator: navigator)
        let item = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
        item.tag = rawValue
        vc.tabBarItem = item
        return vc
    }
}

class HomeTabBarController: UITabBarController, Navigatable {

    var viewModel: HomeTabBarViewModel?
    var navigator: Navigator!

    init(viewModel: ViewModel?, navigator: Navigator) {
        self.viewModel = viewModel as? HomeTabBarViewModel
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        makeUI()
        bindViewModel()
    }

    func makeUI() {
        themeService.typeStream.observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (theme) in
                self?.updateTabBarAppearance(with: theme.associatedObject)
            }).disposed(by: rx.disposeBag)
    }

    private func updateTabBarAppearance(with theme: Theme) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        // 官方：白/深底 + 顶部细线；选中蓝，未选中灰
        appearance.backgroundColor = theme.primary
        appearance.shadowColor = theme.separator

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = theme.textGray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: theme.textGray]
        itemAppearance.selected.iconColor = theme.secondary
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: theme.secondary]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = theme.secondary
        tabBar.unselectedItemTintColor = theme.text

        // Force immediate update
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()
    }

    func bindViewModel() {
        guard let viewModel = viewModel else { return }

        let input = HomeTabBarViewModel.Input()
        let output = viewModel.transform(input: input)

        output.tabBarItems.delay(.milliseconds(50)).drive(onNext: { [weak self] (tabBarItems) in
            if let strongSelf = self {
                let controllers = tabBarItems.map { $0.getController(with: viewModel.viewModel(for: $0), navigator: strongSelf.navigator) }
                strongSelf.setViewControllers(controllers, animated: false)
            }
        }).disposed(by: rx.disposeBag)
    }
}
