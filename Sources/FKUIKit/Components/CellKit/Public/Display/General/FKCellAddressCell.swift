import FKCoreKit
import UIKit

/// Multi-line address row with optional default badge (D-43).
@MainActor
public final class FKCellAddressCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellAddressRow

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

  public func apply(_ configuration: FKCellAddressConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellAddressConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    iconSlot.apply(FKCellIconContent(symbolName: "mappin.and.ellipse"))
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)

    let addressText = configuration.addressLines.joined(separator: "\n")
    layout.contentStack.setTitle(addressText, numberOfLines: 0)
    layout.contentStack.setSubtitle(configuration.contactLine)

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
    accessibilityLabel = addressText
  }

  public func configure(with viewModel: FKCellAddressRow) {
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
