import FKCoreKit
import UIKit

/// Single- or multi-select row with leading checkmark slot (I-03).
@MainActor
public final class FKCellSelectionCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellSelectionRow

  private let layout = FKCellStandardRowLayout()
  private let checkmarkSlot = FKCellLeadingCheckmarkSlot()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a selection row configuration with default appearance.
  public func apply(_ configuration: FKCellSelectionConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies a selection row configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellSelectionConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    layout.applyAppearance(appearance)
    checkmarkSlot.apply(
      isSelected: configuration.isSelected,
      reservesSpaceWhenUnselected: configuration.reservesLeadingSpaceWhenUnselected
    )
    layout.contentStack.setLeadingContent(checkmarkSlot, width: FKCellLayoutMetrics.checkmarkColumnWidth)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.subtitle)
    layout.contentStack.setDetail(nil)
    layout.contentStack.setAccessoryViews([])

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
    accessibilityLabel = [configuration.title, configuration.subtitle]
      .compactMap { value in
        guard let value, !value.isEmpty else { return nil }
        return value
      }
      .joined(separator: ", ")
    accessibilityTraits = configuration.isSelected ? [.selected, .button] : [.button]
  }

  public func configure(with viewModel: FKCellSelectionRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    checkmarkSlot.reset()
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
