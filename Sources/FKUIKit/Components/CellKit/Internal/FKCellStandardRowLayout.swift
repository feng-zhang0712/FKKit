import UIKit

/// Shared chrome for standard three-zone CellKit table rows.
@MainActor
final class FKCellStandardRowLayout {
  let groupedBackground = FKCellGroupedBackgroundView()
  let contentStack = FKCellContentStack()
  let accessoryHost = FKCellAccessoryHostView()
  private let separator = FKCellSeparatorLayout.makeDivider()

  private weak var contentView: UIView?
  private var separatorLeadingToMarginConstraint: NSLayoutConstraint?
  private var separatorLeadingToTitleConstraint: NSLayoutConstraint?
  private(set) var appearance: FKCellAppearanceConfiguration = .default

  func install(in contentView: UIView) {
    guard self.contentView == nil else { return }
    self.contentView = contentView

    groupedBackground.translatesAutoresizingMaskIntoConstraints = false
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(groupedBackground)
    contentView.addSubview(contentStack)
    contentView.addSubview(separator)

    let insets = appearance.contentInsets
    NSLayoutConstraint.activate([
      groupedBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
      groupedBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      groupedBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      groupedBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      contentStack.heightAnchor.constraint(
        greaterThanOrEqualToConstant: appearance.minimumRowHeight - insets.top - insets.bottom
      ),

      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
    ])

    separatorLeadingToMarginConstraint = separator.leadingAnchor.constraint(
      equalTo: contentView.leadingAnchor,
      constant: insets.left
    )
    separatorLeadingToTitleConstraint = separator.leadingAnchor.constraint(
      equalTo: contentStack.titleLabel.leadingAnchor
    )
    separatorLeadingToMarginConstraint?.isActive = true
  }

  func applyAppearance(_ appearance: FKCellAppearanceConfiguration) {
    self.appearance = appearance
    contentStack.applyAppearance(appearance)
  }

  struct ChromeOptions {
    var groupConfiguration: FKCellGroupConfiguration?
    var separatorPolicy: FKCellSeparatorPolicy
    var isLastInSection: Bool
    var isEnabled: Bool
  }

  func applyChrome(_ options: ChromeOptions, to host: FKCellChromeHost) {
    groupedBackground.apply(options.groupConfiguration)

    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: options.separatorPolicy,
      isLastInSection: options.isLastInSection
    )
    applySeparatorInset(policy: options.separatorPolicy)

    let enabled = options.isEnabled
    host.isUserInteractionEnabled = enabled
    contentStack.alpha = enabled ? 1 : 0.5

    if options.groupConfiguration != nil {
      host.backgroundColor = .clear
      host.contentView.backgroundColor = .clear
    } else {
      host.backgroundColor = appearance.cellBackgroundColor
      host.contentView.backgroundColor = appearance.cellBackgroundColor
    }
  }

  func applySeparatorInset(policy: FKCellSeparatorPolicy) {
    switch policy {
    case .insetFromLeadingContent:
      separatorLeadingToMarginConstraint?.isActive = false
      separatorLeadingToTitleConstraint?.isActive = true
    case .fullWidth:
      separatorLeadingToTitleConstraint?.isActive = false
      separatorLeadingToMarginConstraint?.constant = 0
      separatorLeadingToMarginConstraint?.isActive = true
    case .automatic, .none:
      separatorLeadingToTitleConstraint?.isActive = false
      separatorLeadingToMarginConstraint?.constant = appearance.contentInsets.left
      separatorLeadingToMarginConstraint?.isActive = true
    }
  }

  func resetForReuse() {
    contentStack.setLeadingContent(nil, width: 0)
    contentStack.setTitle(nil)
    contentStack.setSubtitle(nil)
    contentStack.setDetail(nil)
    contentStack.setAccessoryViews([])
    accessoryHost.apply(.none, appearance: appearance)
    groupedBackground.apply(nil)
  }
}
