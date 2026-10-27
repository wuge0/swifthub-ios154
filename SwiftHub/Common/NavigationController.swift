//
//  NavigationController.swift
//  SwiftHub
//
//  Created by Khoren Markosyan on 1/4/17.
//  Copyright © 2017 Khoren Markosyan. All rights reserved.
//

import UIKit
import RxSwift

class NavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return globalStatusBarStyle.value
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        interactivePopGestureRecognizer?.delegate = nil // Enable default iOS back swipe gesture

//        navigationBar.isTranslucent = false
        navigationBar.prefersLargeTitles = true
        navigationBar.backIndicatorImage = UIImage(named: "icon_navigation_back")!
        navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "icon_navigation_back")!

        navigationBar.theme.tintColor = themeService.attribute { $0.secondary }
        navigationBar.theme.titleTextAttributes = themeService.attribute { [NSAttributedString.Key.foregroundColor: $0.text] }

        // 导航栏外观对齐官方：主题底色 + 1px 描边，标题用正文色
        themeService.typeStream.observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (themeType) in
                guard let self = self else { return }
                let theme = themeType.associatedObject
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = theme.primary
                appearance.shadowColor = theme.separator
                appearance.titleTextAttributes = [.foregroundColor: theme.text]
                appearance.largeTitleTextAttributes = [
                    .foregroundColor: theme.text,
                    .font: UIFont.systemFont(ofSize: 34, weight: .bold)
                ]
                self.navigationBar.standardAppearance = appearance
                self.navigationBar.scrollEdgeAppearance = appearance
                self.navigationBar.compactAppearance = appearance
            }).disposed(by: rx.disposeBag)
    }
}
