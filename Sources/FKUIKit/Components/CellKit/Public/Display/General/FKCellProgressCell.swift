import FKCoreKit
import UIKit

/// Inline progress row with ``FKProgressBar`` (D-35).
@MainActor
public final class FKCellProgressCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellProgressRow

  private let groupedBackground = FKCellGroupedBackgroundView()
  private let rootStack = UIStackView()
  private let headerRow = UIStackView()
  private let iconSlot = FKCellIconSlotView()
  private let titleLabel = UILabel()
  private let percentLabel = UILabel()
  private let progressBar = FKProgressBar()
  private let separator = FKCellSeparatorLayout.makeDivider()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellProgressConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellProgressConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.title
    if let percent = configuration.percentText {
      percentLabel.text = percent
      percentLabel.isHidden = false
    } else {
      percentLabel.isHidden = true
    }

    if let icon = configuration.leadingIcon {
      iconSlot.apply(icon)
      iconSlot.isHidden = false
    } else {
      iconSlot.isHidden = true
    }

    progressBar.setProgress(configuration.progress, animated: false)

    groupedBackground.apply(nil)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled
    alpha = configuration.isEnabled ? 1 : 0.5
    selectionStyle = .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellProgressRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    iconSlot.reset()
    titleLabel.text = nil
    percentLabel.text = nil
    progressBar.setProgress(0, animated: false)
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    groupedBackground.translatesAutoresizingMaskIntoConstraints = false
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    headerRow.axis = .horizontal
    headerRow.alignment = .center
    headerRow.spacing = FKCellLayoutMetrics.iconColumnSpacing

    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

    percentLabel.font = .preferredFont(forTextStyle: .footnote)
    percentLabel.textColor = .secondaryLabel
    percentLabel.setContentHuggingPriority(.required, for: .horizontal)

    progressBar.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false

    headerRow.addArrangedSubview(iconSlot)
    headerRow.addArrangedSubview(titleLabel)
    headerRow.addArrangedSubview(percentLabel)
    rootStack.addArrangedSubview(headerRow)
    rootStack.addArrangedSubview(progressBar)

    contentView.addSubview(groupedBackground)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      groupedBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
      groupedBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      groupedBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      groupedBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      iconSlot.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.iconColumnWidth),
      progressBar.heightAnchor.constraint(equalToConstant: 4),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
