import FKCoreKit
import UIKit

/// Row with trailing numeric badge for counts and unread tallies (D-34).
@MainActor
public final class FKCellBadgeCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellBadgeRow

  private let layout = FKCellStandardRowLayout()
  private let iconSlot = FKCellIconSlotView()
  private let trailingHost = FKCellTrailingContentHostView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellBadgeConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellBadgeConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    if let icon = configuration.leadingIcon {
      iconSlot.apply(icon)
      layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    } else {
      layout.contentStack.setLeadingContent(nil, width: 0)
    }
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.subtitle)
    trailingHost.apply(
      .badge(configuration.badgeConfiguration),
      badgeCount: configuration.badgeCount,
      appearance: appearance
    )
    layout.contentStack.setAccessoryViews([trailingHost])

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellBadgeRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    iconSlot.reset()
    trailingHost.reset()
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)
  }
}
