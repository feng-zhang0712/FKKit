import FKCoreKit
import UIKit

/// Payment method row with brand icon and masked card number (D-30).
@MainActor
public final class FKCellPaymentMethodCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellPaymentMethodRow

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

  public func apply(_ configuration: FKCellPaymentMethodConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellPaymentMethodConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    iconSlot.apply(configuration.brandIcon)
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.maskedNumber)
    layout.contentStack.setSubtitle(configuration.expiry)

    var trailing: FKCellTrailingContent = configuration.showsDisclosure ? .disclosure : .none
    if let badge = configuration.badge {
      trailing = .statusPill(badge)
    }
    trailingHost.apply(trailing, appearance: appearance)
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
    accessibilityLabel = configuration.maskedNumber
  }

  public func configure(with viewModel: FKCellPaymentMethodRow) {
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
