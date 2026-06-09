import FKCoreKit
import UIKit

/// Vertical or horizontal action button stack for alerts.
@MainActor
final class FKAlertButtonStackView: UIView {
  var onActionSelected: ((FKAlertResolvedAction) -> Void)?

  private let stackView = UIStackView()
  private var resolvedActions: [FKAlertResolvedAction] = []
  private var configuration = FKAlertConfiguration()
  private var actionButtons: [Int: FKButton] = [:]

  override var intrinsicContentSize: CGSize {
    let fittingWidth = bounds.width > 1 ? bounds.width : 320
    return CGSize(
      width: bounds.width > 1 ? bounds.width : UIView.noIntrinsicMetric,
      height: measuredHeight(forWidth: fittingWidth)
    )
  }

  /// Sums arranged control heights without `systemLayoutSizeFitting` (avoids conflicts with `height >= 44`).
  func measuredHeight(forWidth width: CGFloat) -> CGFloat {
    let arrangedSubviews = stackView.arrangedSubviews
    guard !arrangedSubviews.isEmpty else { return 0 }

    var totalHeight: CGFloat = 0
    for (index, subview) in arrangedSubviews.enumerated() {
      if index > 0 { totalHeight += stackView.spacing }
      totalHeight += measuredArrangedSubviewHeight(subview, fittingWidth: max(1, width))
    }
    return totalHeight
  }

  private func measuredArrangedSubviewHeight(_ subview: UIView, fittingWidth: CGFloat) -> CGFloat {
    if let row = subview as? UIStackView, row.axis == .horizontal {
      let columnCount = CGFloat(max(1, row.arrangedSubviews.count))
      let rowSpacing = row.spacing * CGFloat(max(0, row.arrangedSubviews.count - 1))
      let columnWidth = max(1, (fittingWidth - rowSpacing) / columnCount)
      return row.arrangedSubviews
        .map { measuredArrangedSubviewHeight($0, fittingWidth: columnWidth) }
        .max() ?? 44
    }

    if let button = subview as? FKButton {
      return resolvedControlHeight(for: button)
    }

    return max(44, subview.sizeThatFits(
      CGSize(width: fittingWidth, height: .greatestFiniteMagnitude)
    ).height)
  }

  private func resolvedControlHeight(for button: FKButton) -> CGFloat {
    let intrinsicHeight = button.intrinsicContentSize.height
    if intrinsicHeight == UIView.noIntrinsicMetric || intrinsicHeight <= 0 {
      return 44
    }
    return max(44, intrinsicHeight.rounded(.up))
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.distribution = .fillProportionally
    stackView.translatesAutoresizingMaskIntoConstraints = false
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .vertical)
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(
    resolvedActions: [FKAlertResolvedAction],
    configuration: FKAlertConfiguration,
    isPrimaryEnabled: Bool,
    destructiveEnabledProvider: @escaping (FKAlertResolvedAction) -> Bool
  ) {
    self.resolvedActions = resolvedActions
    self.configuration = configuration
    rebuildButtons(
      isPrimaryEnabled: isPrimaryEnabled,
      destructiveEnabledProvider: destructiveEnabledProvider
    )
  }

  func setPrimaryEnabled(_ isEnabled: Bool) {
    resolvedActions.filter { $0.role == .primary }.forEach { actionButtons[$0.sourceIndex]?.isEnabled = isEnabled }
  }

  func updateDestructiveEnabled(_ provider: (FKAlertResolvedAction) -> Bool) {
    resolvedActions.filter { $0.role == .destructive }.forEach { action in
      actionButtons[action.sourceIndex]?.isEnabled = provider(action)
    }
  }

  func refreshDestructiveAccessibility(isConfirmationRequired: Bool, isConfirmationChecked: Bool) {
    guard isConfirmationRequired else { return }
    resolvedActions.filter { $0.role == .destructive }.forEach { action in
      guard let button = actionButtons[action.sourceIndex] else { return }
      var hint = configuration.accessibility.destructiveHint
      if !isConfirmationChecked {
        let requirement = FKUIKitI18n.string("fkuikit.alert.destructive_requires_confirmation")
        hint = [hint, requirement].compactMap { $0 }.joined(separator: " ")
      }
      button.accessibilityHint = hint
    }
  }

  func setLoading(_ isLoading: Bool) {
    resolvedActions.filter { $0.role == .primary || $0.role == .destructive }.forEach { action in
      actionButtons[action.sourceIndex]?.setLoading(isLoading, presentation: .overlay(dimmedContentAlpha: 0.35))
    }
  }

  private func rebuildButtons(
    isPrimaryEnabled: Bool,
    destructiveEnabledProvider: (FKAlertResolvedAction) -> Bool
  ) {
    stackView.arrangedSubviews.forEach { view in
      stackView.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    actionButtons.removeAll()
    stackView.spacing = configuration.appearance.buttonSpacing
    invalidateIntrinsicContentSize()

    let primaryActions = resolvedActions.filter { $0.role == .primary }
    let destructiveActions = resolvedActions.filter { $0.role == .destructive }
    let cancelActions = resolvedActions.filter { $0.role == .cancel }

    if configuration.buttonLayout == .horizontalPair,
       primaryActions.count == 2,
       destructiveActions.isEmpty {
      stackView.addArrangedSubview(makeHorizontalPair(primaryActions, isPrimaryEnabled: isPrimaryEnabled))
    } else {
      primaryActions.forEach { action in
        stackView.addArrangedSubview(makeButton(for: action, isEnabled: isPrimaryEnabled))
      }
    }

    destructiveActions.forEach { action in
      stackView.addArrangedSubview(makeButton(for: action, isEnabled: destructiveEnabledProvider(action)))
    }
    cancelActions.forEach { action in
      stackView.addArrangedSubview(makeButton(for: action, isEnabled: true))
    }
  }

  private func makeHorizontalPair(
    _ actions: [FKAlertResolvedAction],
    isPrimaryEnabled: Bool
  ) -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = configuration.appearance.buttonSpacing
    row.distribution = .fillEqually
    actions.forEach { action in
      row.addArrangedSubview(makeButton(for: action, isEnabled: isPrimaryEnabled))
    }
    return row
  }

  private func makeButton(for resolved: FKAlertResolvedAction, isEnabled: Bool) -> FKButton {
    let button = FKButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.content = .textOnly
    button.setTitle(
      .init(text: resolved.action.title, font: buttonFont(for: resolved.role), color: titleColor(for: resolved.role)),
      for: .normal
    )
    button.setAppearances(.init(normal: appearance(for: resolved.role)))
    button.minimumTouchTargetSize = CGSize(width: 44, height: 44)
    button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    button.setContentHuggingPriority(.required, for: .vertical)
    button.setContentCompressionResistancePriority(.required, for: .vertical)
    button.isEnabled = isEnabled
    button.accessibilityTraits = .button
    if resolved.role == .destructive, let hint = configuration.accessibility.destructiveHint {
      button.accessibilityHint = hint
    }
    button.addAction(UIAction { [weak self] _ in
      self?.onActionSelected?(resolved)
    }, for: .touchUpInside)
    actionButtons[resolved.sourceIndex] = button
    return button
  }

  private func buttonFont(for role: FKAlertResolvedAction.Role) -> UIFont {
    switch role {
    case .cancel:
      return .systemFont(ofSize: 17, weight: .semibold)
    default:
      return .systemFont(ofSize: 17, weight: .regular)
    }
  }

  private func titleColor(for role: FKAlertResolvedAction.Role) -> UIColor {
    switch role {
    case .destructive:
      return .white
    case .cancel:
      return .label
    case .primary:
      return .white
    }
  }

  private func appearance(for role: FKAlertResolvedAction.Role) -> FKButtonAppearance {
    let corner = FKButtonCornerStyle(corner: .fixed(12))
    switch role {
    case .primary:
      return .filled(backgroundColor: .systemBlue, cornerStyle: corner)
    case .destructive:
      return .filled(backgroundColor: .systemRed, cornerStyle: corner)
    case .cancel:
      return .ghost(cornerStyle: corner)
    }
  }
}
