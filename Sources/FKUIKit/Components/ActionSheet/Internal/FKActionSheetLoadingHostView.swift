import UIKit

@MainActor
protocol FKActionSheetLoadingHostViewDelegate: AnyObject {
  func loadingHostView(_ view: FKActionSheetLoadingHostView, didSelectCancel action: FKActionSheetAction)
}

/// Hosts the loading body and optional cancel row while ``FKActionSheetContentMode/loading(_:)`` is active.
@MainActor
final class FKActionSheetLoadingHostView: UIView {
  weak var delegate: FKActionSheetLoadingHostViewDelegate?

  private let contentContainer = UIView()
  private let cancelContainer = UIView()
  private var embeddedLoadingView: UIView?
  private var activityIndicator: UIActivityIndicatorView?
  private var standardStack: UIStackView?
  private var cancelRowView: FKActionSheetLoadingCancelRowView?
  private var contentBottomToCancelConstraint: NSLayoutConstraint?
  private var contentBottomToHostConstraint: NSLayoutConstraint?
  private var cancelBottomConstraint: NSLayoutConstraint?
  private var bottomSafeAreaInset: CGFloat = 0
  private var loadingConfiguration: FKActionSheetLoadingConfiguration?
  private var appearance = FKActionSheetAppearance.default
  private var cancelAction: FKActionSheetAction?

  override init(frame: CGRect) {
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
    insetsLayoutMarginsFromSafeArea = false

    contentContainer.translatesAutoresizingMaskIntoConstraints = false
    cancelContainer.translatesAutoresizingMaskIntoConstraints = false

    addSubview(contentContainer)
    addSubview(cancelContainer)

    let contentBottomToCancel = contentContainer.bottomAnchor.constraint(
      equalTo: cancelContainer.topAnchor,
      constant: 0
    )
    contentBottomToCancelConstraint = contentBottomToCancel

    let contentBottomToHost = contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
    contentBottomToHostConstraint = contentBottomToHost
    contentBottomToHost.isActive = false

    let cancelBottom = cancelContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
    cancelBottomConstraint = cancelBottom

    NSLayoutConstraint.activate([
      contentContainer.topAnchor.constraint(equalTo: topAnchor),
      contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),

      cancelContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
      cancelContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
      cancelBottom,
    ])

    let cancelTap = UITapGestureRecognizer(target: self, action: #selector(handleCancelTap))
    cancelContainer.addGestureRecognizer(cancelTap)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(
    loadingConfiguration: FKActionSheetLoadingConfiguration,
    appearance: FKActionSheetAppearance,
    cancelAction: FKActionSheetAction?,
    layoutWidth: CGFloat
  ) {
    self.loadingConfiguration = loadingConfiguration
    self.appearance = appearance
    self.cancelAction = cancelAction
    backgroundColor = appearance.backgroundColor

    updateCancelLayout(
      loadingConfiguration: loadingConfiguration,
      appearance: appearance,
      cancelAction: cancelAction
    )
    applyLoadingContent(
      loadingConfiguration: loadingConfiguration,
      appearance: appearance,
      layoutWidth: layoutWidth
    )
    applyCancelRow(
      loadingConfiguration: loadingConfiguration,
      appearance: appearance,
      cancelAction: cancelAction
    )
  }

  func updateLayoutIfNeeded(layoutWidth: CGFloat) {
    guard let loadingConfiguration else { return }
    updateCustomLoadingLayoutIfNeeded(
      loadingConfiguration: loadingConfiguration,
      layoutWidth: layoutWidth
    )
  }

  /// Lifts the cancel row above the home indicator (mirrors the table footer used for action rows).
  func updateBottomSafeAreaInset(_ inset: CGFloat) {
    let bottom = max(0, inset)
    guard abs(bottomSafeAreaInset - bottom) > 0.5 else { return }
    bottomSafeAreaInset = bottom
    cancelBottomConstraint?.constant = -bottom
  }

  func measuredContentHeight(for width: CGFloat) -> CGFloat {
    guard let loadingConfiguration else {
      return appearance.minimumRowHeight
    }

    var total = loadingConfiguration.preferredPanelHeight
    if showsCancelRow(loadingConfiguration: loadingConfiguration, cancelAction: cancelAction) {
      total += appearance.cancelGroupSpacing
      total += appearance.minimumRowHeight
    }
    return max(total, appearance.minimumRowHeight)
  }

  func accessibilityElementToFocus() -> Any? {
    embeddedLoadingView ?? contentContainer
  }

  /// Height available to the loading body for custom view builders.
  func resolvedLoadingBodyHeight() -> CGFloat {
    loadingConfiguration?.preferredPanelHeight ?? appearance.minimumRowHeight
  }

  /// Releases loading body and cancel row subviews when leaving loading mode.
  func teardownContent() {
    activityIndicator?.stopAnimating()
    activityIndicator = nil

    embeddedLoadingView?.removeFromSuperview()
    embeddedLoadingView = nil

    standardStack?.removeFromSuperview()
    standardStack = nil

    cancelRowView?.removeFromSuperview()
    cancelRowView = nil

    contentContainer.subviews.forEach { $0.removeFromSuperview() }
    cancelContainer.isHidden = true

    loadingConfiguration = nil
    cancelAction = nil

    contentContainer.isAccessibilityElement = false
    contentContainer.accessibilityLabel = nil
    contentContainer.accessibilityTraits = []
  }

  private func applyLoadingContent(
    loadingConfiguration: FKActionSheetLoadingConfiguration,
    appearance: FKActionSheetAppearance,
    layoutWidth: CGFloat
  ) {
    let insets = loadingConfiguration.contentInsets
    contentContainer.directionalLayoutMargins = insets

    switch loadingConfiguration.content {
    case .standard(let standard):
      applyStandardLoadingContent(standard, appearance: appearance)
    case .custom(let custom):
      applyCustomLoadingContent(
        custom,
        appearance: appearance,
        layoutWidth: layoutWidth,
        contentHeight: resolvedLoadingBodyHeight()
      )
    }
  }

  private func applyStandardLoadingContent(
    _ content: FKActionSheetStandardLoadingContent,
    appearance: FKActionSheetAppearance
  ) {
    embeddedLoadingView?.removeFromSuperview()
    embeddedLoadingView = nil
    activityIndicator = nil

    let stack = standardStack ?? UIStackView()
    standardStack = stack
    stack.arrangedSubviews.forEach { view in
      stack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = content.stackSpacing
    stack.translatesAutoresizingMaskIntoConstraints = false

    if content.showsActivityIndicator {
      let indicator = UIActivityIndicatorView(style: content.activityIndicatorStyle)
      indicator.translatesAutoresizingMaskIntoConstraints = false
      indicator.color = content.activityIndicatorColor
      indicator.startAnimating()
      indicator.accessibilityLabel = FKUIKitI18n.string("fkuikit.common.loading")
      activityIndicator = indicator
      stack.addArrangedSubview(indicator)
    }

    if let title = content.title, !title.isEmpty {
      let label = UILabel()
      label.font = content.titleFont ?? .preferredFont(forTextStyle: .headline)
      label.textColor = content.titleColor ?? appearance.headerTitleColor
      label.textAlignment = .center
      label.numberOfLines = 0
      label.text = title
      stack.addArrangedSubview(label)
    }

    if let message = content.message, !message.isEmpty {
      let label = UILabel()
      label.font = content.messageFont ?? appearance.resolvedHeaderMessageFont()
      label.textColor = content.messageColor ?? appearance.headerMessageColor
      label.textAlignment = .center
      label.numberOfLines = 0
      label.text = message
      stack.addArrangedSubview(label)
    }

    if stack.superview == nil {
      contentContainer.addSubview(stack)
      NSLayoutConstraint.activate([
        stack.centerXAnchor.constraint(equalTo: contentContainer.layoutMarginsGuide.centerXAnchor),
        stack.centerYAnchor.constraint(equalTo: contentContainer.layoutMarginsGuide.centerYAnchor),
        stack.leadingAnchor.constraint(greaterThanOrEqualTo: contentContainer.layoutMarginsGuide.leadingAnchor),
        stack.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.layoutMarginsGuide.trailingAnchor),
        stack.topAnchor.constraint(greaterThanOrEqualTo: contentContainer.layoutMarginsGuide.topAnchor),
        stack.bottomAnchor.constraint(lessThanOrEqualTo: contentContainer.layoutMarginsGuide.bottomAnchor),
      ])
    }

    stack.isAccessibilityElement = true
    stack.accessibilityTraits = [.updatesFrequently]
    if let accessibilityLabel = content.accessibilityLabel, !accessibilityLabel.isEmpty {
      stack.accessibilityLabel = accessibilityLabel
    } else {
      let parts = [content.title, content.message].compactMap { value -> String? in
        guard let value, !value.isEmpty else { return nil }
        return value
      }
      stack.accessibilityLabel = parts.isEmpty ? FKUIKitI18n.string("fkuikit.common.loading") : parts.joined(separator: ", ")
    }

    embeddedLoadingView = stack
  }

  private func applyCustomLoadingContent(
    _ custom: FKActionSheetCustomLoadingContent,
    appearance: FKActionSheetAppearance,
    layoutWidth: CGFloat,
    contentHeight: CGFloat
  ) {
    standardStack?.removeFromSuperview()
    standardStack = nil
    activityIndicator = nil

    let context = FKActionSheetLoadingBuildContext(
      appearance: appearance,
      boundsWidth: layoutWidth,
      boundsHeight: contentHeight
    )

    contentContainer.isAccessibilityElement = true
    contentContainer.accessibilityTraits = [.updatesFrequently]
    contentContainer.accessibilityLabel = custom.accessibilityLabel ?? FKUIKitI18n.string("fkuikit.common.loading")

    if let embeddedLoadingView, let update = custom.provider.update {
      update(context, embeddedLoadingView)
    } else {
      embeddedLoadingView?.removeFromSuperview()
      let built = custom.provider.build(context)
      self.embeddedLoadingView = built
      if custom.fillsAvailableArea {
        installFillingLoadingSubview(built)
      } else {
        installCenteredLoadingSubview(built)
      }
    }
  }

  private func installFillingLoadingSubview(_ view: UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    contentContainer.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: contentContainer.layoutMarginsGuide.topAnchor),
      view.leadingAnchor.constraint(equalTo: contentContainer.layoutMarginsGuide.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: contentContainer.layoutMarginsGuide.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: contentContainer.layoutMarginsGuide.bottomAnchor),
    ])
  }

  private func installCenteredLoadingSubview(_ view: UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    contentContainer.addSubview(view)
    NSLayoutConstraint.activate([
      view.centerXAnchor.constraint(equalTo: contentContainer.layoutMarginsGuide.centerXAnchor),
      view.centerYAnchor.constraint(equalTo: contentContainer.layoutMarginsGuide.centerYAnchor),
      view.leadingAnchor.constraint(greaterThanOrEqualTo: contentContainer.layoutMarginsGuide.leadingAnchor),
      view.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.layoutMarginsGuide.trailingAnchor),
      view.topAnchor.constraint(greaterThanOrEqualTo: contentContainer.layoutMarginsGuide.topAnchor),
      view.bottomAnchor.constraint(lessThanOrEqualTo: contentContainer.layoutMarginsGuide.bottomAnchor),
    ])
  }

  private func updateCustomLoadingLayoutIfNeeded(
    loadingConfiguration: FKActionSheetLoadingConfiguration,
    layoutWidth: CGFloat
  ) {
    guard case .custom(let custom) = loadingConfiguration.content,
          let embeddedLoadingView,
          let update = custom.provider.update
    else { return }

    let context = FKActionSheetLoadingBuildContext(
      appearance: appearance,
      boundsWidth: layoutWidth,
      boundsHeight: max(contentContainer.bounds.height, resolvedLoadingBodyHeight())
    )
    update(context, embeddedLoadingView)
  }

  private func updateCancelLayout(
    loadingConfiguration: FKActionSheetLoadingConfiguration,
    appearance: FKActionSheetAppearance,
    cancelAction: FKActionSheetAction?
  ) {
    let showsCancel = showsCancelRow(
      loadingConfiguration: loadingConfiguration,
      cancelAction: cancelAction
    )
    cancelContainer.isHidden = !showsCancel
    contentBottomToCancelConstraint?.constant = showsCancel ? -appearance.cancelGroupSpacing : 0
    contentBottomToCancelConstraint?.isActive = showsCancel
    contentBottomToHostConstraint?.isActive = !showsCancel
  }

  private func applyCancelRow(
    loadingConfiguration: FKActionSheetLoadingConfiguration,
    appearance: FKActionSheetAppearance,
    cancelAction: FKActionSheetAction?
  ) {
    guard showsCancelRow(loadingConfiguration: loadingConfiguration, cancelAction: cancelAction),
          let cancelAction
    else {
      cancelRowView?.removeFromSuperview()
      cancelRowView = nil
      return
    }

    let row = cancelRowView ?? FKActionSheetLoadingCancelRowView()
    cancelRowView = row
    if row.superview == nil {
      row.translatesAutoresizingMaskIntoConstraints = false
      cancelContainer.addSubview(row)
      NSLayoutConstraint.activate([
        row.topAnchor.constraint(equalTo: cancelContainer.topAnchor),
        row.leadingAnchor.constraint(equalTo: cancelContainer.leadingAnchor),
        row.trailingAnchor.constraint(equalTo: cancelContainer.trailingAnchor),
        row.bottomAnchor.constraint(equalTo: cancelContainer.bottomAnchor),
      ])
    }
    row.apply(action: cancelAction, appearance: appearance)
    row.backgroundColor = appearance.cellBackgroundColor
  }

  private func showsCancelRow(
    loadingConfiguration: FKActionSheetLoadingConfiguration,
    cancelAction: FKActionSheetAction?
  ) -> Bool {
    loadingConfiguration.showsCancelWhileLoading && cancelAction != nil
  }

  @objc
  private func handleCancelTap() {
    guard let cancelAction else { return }
    delegate?.loadingHostView(self, didSelectCancel: cancelAction)
  }
}
