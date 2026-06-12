import UIKit

/// Observes highlight/selection on the enclosing table cell to sync separator visibility.
@MainActor
private final class FKCellHighlightSeparatorSyncView: UIView {
  weak var layout: FKCellStandardRowLayout?

  override func layoutSubviews() {
    super.layoutSubviews()
    guard let layout else { return }
    var candidate: UIView? = superview
    while let view = candidate {
      if let cell = view as? UITableViewCell {
        layout.syncSeparatorHighlight(isActive: cell.isHighlighted || cell.isSelected)
        return
      }
      candidate = view.superview
    }
  }
}

/// Shared chrome for standard three-zone CellKit table rows.
@MainActor
final class FKCellStandardRowLayout {
  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  let contentStack = FKCellContentStack()
  private var accessoryHostStorage: FKCellAccessoryHostView?
  private var switchControlStorage: UISwitch?
  private let separator = FKCellSeparatorLayout.makeDivider()

  private weak var contentView: UIView?
  private var separatorLeadingToMarginConstraint: NSLayoutConstraint?
  private var separatorLeadingToTitleConstraint: NSLayoutConstraint?
  private var highlightSyncView: FKCellHighlightSeparatorSyncView?
  private var lastChromeOptions: ChromeOptions?
  private(set) var appearance: FKCellAppearanceConfiguration = .default

  /// Lazily created trailing accessory host; released on ``resetForReuse()``.
  var accessoryHost: FKCellAccessoryHostView {
    if let accessoryHostStorage { return accessoryHostStorage }
    let host = FKCellAccessoryHostView()
    accessoryHostStorage = host
    return host
  }

  /// Lazily created switch for I-01 rows; released on ``resetForReuse()``.
  var switchControl: UISwitch {
    if let switchControlStorage { return switchControlStorage }
    let control = UISwitch()
    control.setContentHuggingPriority(.required, for: .horizontal)
    control.setContentCompressionResistancePriority(.required, for: .horizontal)
    switchControlStorage = control
    return control
  }

  func install(in contentView: UIView) {
    guard self.contentView == nil else { return }
    self.contentView = contentView

    contentStack.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(contentStack)
    contentView.addSubview(separator)

    let insets = appearance.contentInsets
    NSLayoutConstraint.activate([
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

    let syncView = FKCellHighlightSeparatorSyncView()
    syncView.layout = self
    syncView.translatesAutoresizingMaskIntoConstraints = false
    syncView.isUserInteractionEnabled = false
    contentView.addSubview(syncView)
    NSLayoutConstraint.activate([
      syncView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      syncView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      syncView.topAnchor.constraint(equalTo: contentView.topAnchor),
      syncView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    highlightSyncView = syncView
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
    lastChromeOptions = options
    if let contentView {
      groupedBackgroundHost.apply(options.groupConfiguration, in: contentView)
    }

    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: options.separatorPolicy,
      isLastInSection: options.isLastInSection
    )
    applySeparatorInset(policy: options.separatorPolicy)
    syncSeparatorHighlight(isActive: false)

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

  /// Hides the row separator while highlighted/selected, matching UITableView grouped behavior.
  func syncSeparatorHighlight(isActive: Bool) {
    guard let options = lastChromeOptions else { return }
    if isActive, options.separatorPolicy != .none, !options.isLastInSection {
      separator.isHidden = true
      return
    }
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: options.separatorPolicy,
      isLastInSection: options.isLastInSection
    )
  }

  func resetForReuse() {
    contentStack.setLeadingContent(nil, width: 0)
    contentStack.setTitle(nil)
    contentStack.setSubtitle(nil)
    contentStack.setDetail(nil)
    contentStack.setAccessoryViews([])
    accessoryHostStorage?.apply(.none, appearance: appearance)
    accessoryHostStorage = nil
    switchControlStorage = nil
    groupedBackgroundHost.detach()
    lastChromeOptions = nil
  }
}
