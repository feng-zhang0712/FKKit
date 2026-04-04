//
//  AppRootViewController.swift
//  FKUIKitDemo
//

import UIKit

/// 应用根导航：承载「组件演示」列表，子页面由各 `Demos` 下的 ViewController 提供。
final class AppRootViewController: UINavigationController {

  init() {
    super.init(rootViewController: DemoMenuViewController())
    navigationBar.prefersLargeTitles = false
    applySystemNavigationBarAppearance()
  }

  /// 使用与系统设置页类似的 **不透明** 导航栏背景（浅色下为白/灰白，深色模式随 `systemBackground`）。
  private func applySystemNavigationBarAppearance() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = .systemBackground
    appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

    navigationBar.standardAppearance = appearance
    navigationBar.scrollEdgeAppearance = appearance
    navigationBar.compactAppearance = appearance
    navigationBar.compactScrollEdgeAppearance = appearance
    navigationBar.isTranslucent = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
