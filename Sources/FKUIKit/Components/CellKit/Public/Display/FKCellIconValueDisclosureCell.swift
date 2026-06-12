import FKCoreKit
import UIKit

/// Settings row with icon, optional subtitle, trailing value, and chevron (D-14).
@MainActor
public final class FKCellIconValueDisclosureCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellIconValueDisclosureRow

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

  /// Applies an icon value disclosure configuration with default appearance.
  public func apply(_ configuration: FKCellIconValueDisclosureConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies an icon value disclosure configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellIconValueDisclosureConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    layout.applyAppearance(appearance)
    iconSlot.apply(configuration.icon)
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.subtitle)
    layout.contentStack.setDetail(configuration.value, emphasis: .secondary)

    let accessory: FKCellAccessory = configuration.showsDisclosure ? .disclosureIndicator : .none
    layout.accessoryHost.apply(accessory, appearance: appearance)
    layout.contentStack.setAccessoryViews([layout.accessoryHost])

    layout.applyChrome(
      .init(
        groupConfiguration: groupConfiguration,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    layout.contentStack.titleLabel.textColor = configuration.isEnabled ? .label : .tertiaryLabel
    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = [configuration.title, configuration.subtitle, configuration.value]
      .compactMap { value in
        guard let value, !value.isEmpty else { return nil }
        return value
      }
      .joined(separator: ", ")
    accessibilityTraits = configuration.showsDisclosure ? [.button] : []
  }

  public func configure(with viewModel: FKCellIconValueDisclosureRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    iconSlot.reset()
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
    accessibilityTraits = []
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)
  }
}
