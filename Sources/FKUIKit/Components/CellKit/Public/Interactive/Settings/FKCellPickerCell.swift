import FKCoreKit
import UIKit

/// Settings picker row with optional icon, value, and up/down indicator (I-05).
@MainActor
public final class FKCellPickerCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellPickerRow

  /// Called when the user taps the row to present a picker.
  public var onTap: (() -> Void)?

  private let layout = FKCellStandardRowLayout()
  private let iconSlot = FKCellIconSlotView()
  private let pickerIndicator = UIImageView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellPickerConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellPickerConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    layout.applyAppearance(appearance)

    if let icon = configuration.icon {
      iconSlot.apply(icon)
      layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    } else {
      layout.contentStack.setLeadingContent(nil, width: 0)
    }

    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(nil)
    layout.contentStack.setDetail(configuration.value, emphasis: .secondary)
    layout.contentStack.setAccessoryViews([pickerIndicator])

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
    accessibilityLabel = "\(configuration.title), \(configuration.value)"
    accessibilityTraits = configuration.isEnabled ? [.button] : [.notEnabled]
  }

  public func configure(with viewModel: FKCellPickerRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTap = nil
    iconSlot.reset()
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
    accessibilityTraits = []
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .default
    layout.install(in: contentView)

    pickerIndicator.translatesAutoresizingMaskIntoConstraints = false
    pickerIndicator.image = UIImage(systemName: "chevron.up.chevron.down")
    pickerIndicator.tintColor = .tertiaryLabel
    pickerIndicator.contentMode = .scaleAspectFit
    pickerIndicator.setContentHuggingPriority(.required, for: .horizontal)
    NSLayoutConstraint.activate([
      pickerIndicator.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.chevronWidth),
    ])
  }
}
