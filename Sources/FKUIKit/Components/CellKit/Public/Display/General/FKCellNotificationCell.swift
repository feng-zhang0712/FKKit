import FKCoreKit
import UIKit

/// Notification center feed row with unread styling (D-21).
@MainActor
public final class FKCellNotificationCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellNotificationRow

  private let layout = FKCellStandardRowLayout()
  private let iconSlot = FKCellIconSlotView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellNotificationConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellNotificationConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    iconSlot.apply(configuration.icon)
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.body)
    layout.contentStack.setDetail(configuration.timestamp)
    layout.contentStack.setAccessoryViews([])

    FKCellUnreadApplicator.apply(
      presentation: configuration.unread,
      to: self,
      titleLabel: layout.contentStack.titleLabel,
      appearance: appearance
    )

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    if let tint = configuration.unread.backgroundTint, configuration.unread.isUnread {
      contentView.backgroundColor = tint
    }

    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellNotificationRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    iconSlot.reset()
    layout.resetForReuse()
    contentView.backgroundColor = layout.appearance.cellBackgroundColor
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)
  }
}
