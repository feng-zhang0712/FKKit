import UIKit
import FKUIKit

/// Action-sheet style bottom sheet: two actions + cancel, sized with `.contentOnly` (no manual grabber math).
final class SheetActionSheetStyleExampleViewController: FKSheetPresentationExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Action sheet style",
      subtitle: "Report pure content height; FKSheet compensates grabber and home-indicator safe area.",
      notes: """
      Uses `preferredContentSizeReporting = .contentOnly` with `contentRespectsSafeArea`.
      Grabber stays visible; swipe/drag is disabled (`allowsSwipe = false`).
      """
    )

    addPrimaryButton(title: "Present action sheet") { [weak self] in
      guard let self else { return }
      let content = ActionSheetStyleContentViewController()

      var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fitContent]
      configuration.sheet.prefersGrabberVisible = true
      configuration.dismissBehavior.allowsSwipe = false
      configuration.preferredContentSizeReporting = .contentOnly
      configuration.preferredContentSizePolicy = .strict

      FKSheetPresentationController.present(
        contentController: content,
        from: self,
        configuration: configuration,
        delegate: nil,
        handlers: .init(),
        animated: true,
        completion: nil
      )
    }
  }
}

private final class ActionSheetStyleContentViewController: UIViewController {
  private enum Metrics {
    static let rowHeight: CGFloat = 48
    static let verticalPadding: CGFloat = 8
    static let separatorHeight: CGFloat = 1 / UIScreen.main.scale
  }

  private let stack = UIStackView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    stack.axis = .vertical
    stack.spacing = 0
    stack.distribution = .fill
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    let stackHeight = Metrics.rowHeight * 3 + Metrics.separatorHeight * 2
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      stack.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.verticalPadding),
      stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Metrics.verticalPadding),
      stack.heightAnchor.constraint(equalToConstant: stackHeight),
    ])

    stack.addArrangedSubview(makeActionButton(title: "Report content", isDestructive: false))
    stack.addArrangedSubview(makeSeparator())
    stack.addArrangedSubview(makeActionButton(title: "Block user", isDestructive: true))
    stack.addArrangedSubview(makeSeparator())
    stack.addArrangedSubview(makeActionButton(title: "Cancel", isDestructive: false))

    updatePreferredContentSize()
  }

  private func makeActionButton(title: String, isDestructive: Bool) -> UIButton {
    var config = UIButton.Configuration.plain()
    config.title = title
    config.baseForegroundColor = isDestructive ? .systemRed : .label
    config.contentInsets = .zero
    config.titleAlignment = .center
    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.heightAnchor.constraint(equalToConstant: Metrics.rowHeight),
    ])
    button.addAction(UIAction { [weak self] _ in
      self?.dismiss(animated: true)
    }, for: .touchUpInside)
    return button
  }

  private func makeSeparator() -> UIView {
    let line = UIView()
    line.backgroundColor = .separator
    line.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      line.heightAnchor.constraint(equalToConstant: Metrics.separatorHeight),
    ])
    return line
  }

  private func updatePreferredContentSize() {
    let rowCount: CGFloat = 3
    let separatorCount: CGFloat = 2
    let contentHeight = Metrics.verticalPadding * 2
      + rowCount * Metrics.rowHeight
      + separatorCount * Metrics.separatorHeight
    preferredContentSize = CGSize(width: 0, height: contentHeight)
  }
}
