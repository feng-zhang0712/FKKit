//
//  FKBadgeCompleteExampleViewController.swift
//  FKKitExamples
//

import UIKit
import FKUIKit

/// Complete FKBadge showcase with copy-ready usage patterns.
@MainActor
final class FKBadgeCompleteExampleViewController: UIViewController {

  private let stack = UIStackView()
  private let numberTarget = UIView()
  private let textTarget = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    title = "FKBadge Complete"
    setupLayout()
    setupNavigationBadge()
    applyGlobalConfiguration()
    buildSections()
  }

  private func setupLayout() {
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  private func setupNavigationBadge() {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "bell.fill"), for: .normal)
    button.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
    let item = UIBarButtonItem(customView: button)
    navigationItem.rightBarButtonItem = item
    item.fk_showBadgeCount(5, animated: true, animation: .pop())
  }

  private func applyGlobalConfiguration() {
    // Set app-wide baseline style for newly created badges.
    var cfg = FKBadgeConfiguration()
    cfg.backgroundColor = .systemRed
    cfg.titleColor = .white
    cfg.maxDisplayCount = 99
    FKBadgeManager.shared.defaultConfiguration = cfg
  }

  private func buildSections() {
    let dotView = makeTarget(title: "UIView")
    dotView.fk_showBadgeDot(animated: true, animation: .pop())

    let dotButton = UIButton(type: .system)
    dotButton.setTitle("UIButton", for: .normal)
    dotButton.backgroundColor = .tertiarySystemFill
    dotButton.layer.cornerRadius = 10
    dotButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    dotButton.fk_showBadgeDot(animated: true, animation: .pop())

    numberTarget.translatesAutoresizingMaskIntoConstraints = false
    configureTarget(numberTarget, title: "99+")
    numberTarget.fk_showBadgeCount(128, animated: true)

    textTarget.translatesAutoresizingMaskIntoConstraints = false
    configureTarget(textTarget, title: "Text")
    textTarget.fk_showBadgeText("NEW", animated: true, animation: .pop())

    // Customize style: color, font, corner radius, border, and padding.
    var style = FKBadgeConfiguration()
    style.backgroundColor = .systemBlue
    style.titleColor = .white
    style.font = .systemFont(ofSize: 10, weight: .bold)
    style.textCornerRadius = 8
    style.borderWidth = 1
    style.borderColor = .white
    style.horizontalPadding = 7
    numberTarget.fk_badge.configuration = style

    // Custom position and offset.
    numberTarget.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: 10, vertical: -6))

    // Tap callback with weak capture to avoid retain cycles.
    textTarget.fk_badge.onTap = { [weak self] _ in
      self?.textTarget.fk_showBadgeText("Hot", animated: true, animation: .pop())
    }

    let tabBar = UITabBar()
    let inbox = UITabBarItem(title: "Inbox", image: UIImage(systemName: "tray.fill"), tag: 0)
    let profile = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.fill"), tag: 1)
    tabBar.items = [inbox, profile]
    tabBar.selectedItem = inbox
    tabBar.heightAnchor.constraint(equalToConstant: 49).isActive = true
    inbox.fk_setBadgeCount(188, maxDisplay: 99, overflowSuffix: "+")
    profile.fk_showBadgeText("Draft", animated: true, animation: .blink())

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    actions.addArrangedSubview(makeActionButton("Update") { [weak self] in
      self?.numberTarget.fk_badge.updateCount(42, animated: true, animation: .pop())
    })
    actions.addArrangedSubview(makeActionButton("Hide") { [weak self] in
      self?.numberTarget.fk_badge.setHidden(true, animated: true)
    })
    actions.addArrangedSubview(makeActionButton("Show") { [weak self] in
      self?.numberTarget.fk_badge.setHidden(false, animated: true)
      self?.numberTarget.fk_showBadgeCount(42, animated: true)
    })
    actions.addArrangedSubview(makeActionButton("Remove") { [weak self] in
      self?.numberTarget.fk_badge.removeFromTarget()
    })

    let animationButtons = UIStackView()
    animationButtons.axis = .horizontal
    animationButtons.spacing = 8
    animationButtons.distribution = .fillEqually
    animationButtons.addArrangedSubview(makeActionButton("Fade") { [weak self] in
      self?.textTarget.fk_showBadgeCount(5, animated: true, animation: .none)
    })
    animationButtons.addArrangedSubview(makeActionButton("Scale") { [weak self] in
      self?.textTarget.fk_showBadgeCount(5, animated: true, animation: .pop())
    })
    animationButtons.addArrangedSubview(makeActionButton("Blink") { [weak self] in
      self?.textTarget.fk_showBadgeCount(5, animated: true, animation: .blink())
    })

    let globalButtons = UIStackView()
    globalButtons.axis = .horizontal
    globalButtons.spacing = 8
    globalButtons.distribution = .fillEqually
    globalButtons.addArrangedSubview(makeActionButton("Hide All") {
      FKBadgeManager.shared.hideAll(animated: true)
    })
    globalButtons.addArrangedSubview(makeActionButton("Restore All") {
      FKBadgeManager.shared.restoreAll(animated: true)
    })

    [dotView, dotButton, numberTarget, textTarget, tabBar, actions, animationButtons, globalButtons].forEach {
      stack.addArrangedSubview($0)
    }
  }

  private func makeTarget(title: String) -> UIView {
    let v = UIView()
    configureTarget(v, title: title)
    return v
  }

  private func configureTarget(_ target: UIView, title: String) {
    target.backgroundColor = .tertiarySystemFill
    target.layer.cornerRadius = 10
    target.heightAnchor.constraint(equalToConstant: 44).isActive = true
    let label = UILabel()
    label.text = title
    label.textColor = .secondaryLabel
    label.font = .systemFont(ofSize: 12, weight: .medium)
    label.translatesAutoresizingMaskIntoConstraints = false
    target.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: target.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: target.centerYAnchor),
    ])
  }

  private func makeActionButton(_ title: String, action: @escaping () -> Void) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(title, for: .normal)
    b.backgroundColor = .secondarySystemFill
    b.layer.cornerRadius = 8
    b.heightAnchor.constraint(equalToConstant: 36).isActive = true
    b.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return b
  }
}
