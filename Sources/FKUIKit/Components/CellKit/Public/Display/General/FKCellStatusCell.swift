import FKCoreKit
import UIKit

/// Status row with trailing pill, badge, or disclosure (D-33).
@MainActor
public final class FKCellStatusCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellStatusRow

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

  public func apply(_ configuration: FKCellStatusConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellStatusConfiguration,
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
    layout.contentStack.setSubtitle(nil)
    trailingHost.apply(configuration.trailing, badgeCount: configuration.badgeCount, appearance: appearance)
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

  public func configure(with viewModel: FKCellStatusRow) {
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
