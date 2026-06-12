import FKCoreKit
import UIKit

/// Title, subtitle, and ``UISwitch`` in card chrome (X-39).
@MainActor
public final class FKFormCellSwitchCaptionCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormSwitchCaptionRow

  /// Called when the switch value changes.
  public var onValueChanged: ((Bool) -> Void)?

  private let cardBackground = UIView()
  private let rootStack = UIStackView()
  private let textStack = UIStackView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let switchControl = UISwitch()
  private var isApplyingConfiguration = false

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellSwitchCaptionConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellSwitchCaptionConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.title
    if let subtitle = configuration.subtitle, !subtitle.isEmpty {
      subtitleLabel.text = subtitle
      subtitleLabel.isHidden = false
    } else {
      subtitleLabel.isHidden = true
    }

    isApplyingConfiguration = true
    switchControl.isOn = configuration.isOn
    switchControl.isEnabled = configuration.isEnabled
    isApplyingConfiguration = false

    cardBackground.backgroundColor = appearance.cellBackgroundColor
    cardBackground.layer.cornerRadius = FKFormLayoutMetrics.cardCornerRadius
    cardBackground.layer.cornerCurve = .continuous

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.title
    switchControl.accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKFormSwitchCaptionRow) {
    var configuration = viewModel.configuration
    configuration.isOn = viewModel.isOn
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onValueChanged = nil
    titleLabel.text = nil
    subtitleLabel.text = nil
    subtitleLabel.isHidden = true
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    cardBackground.translatesAutoresizingMaskIntoConstraints = false
    rootStack.axis = .horizontal
    rootStack.alignment = .center
    rootStack.spacing = 12
    rootStack.translatesAutoresizingMaskIntoConstraints = false
    rootStack.isLayoutMarginsRelativeArrangement = true
    rootStack.layoutMargins = FKFormLayoutMetrics.cardContentInsets

    textStack.axis = .vertical
    textStack.spacing = 4
    textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.numberOfLines = 0
    titleLabel.adjustsFontForContentSizeCategory = true

    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.isHidden = true

    switchControl.addTarget(self, action: #selector(handleSwitchChanged), for: .valueChanged)
    switchControl.setContentHuggingPriority(.required, for: .horizontal)

    textStack.addArrangedSubview(titleLabel)
    textStack.addArrangedSubview(subtitleLabel)
    rootStack.addArrangedSubview(textStack)
    rootStack.addArrangedSubview(switchControl)

    contentView.addSubview(cardBackground)
    contentView.addSubview(rootStack)
    NSLayoutConstraint.activate([
      cardBackground.topAnchor.constraint(equalTo: rootStack.topAnchor),
      cardBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      cardBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      cardBackground.bottomAnchor.constraint(equalTo: rootStack.bottomAnchor),

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
    ])
  }

  @objc private func handleSwitchChanged() {
    guard !isApplyingConfiguration else { return }
    onValueChanged?(switchControl.isOn)
  }
}
