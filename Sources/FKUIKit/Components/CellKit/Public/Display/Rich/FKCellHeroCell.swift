import FKCoreKit
import UIKit

/// Centered hero description card for settings-style sections (D-06).
@MainActor
public final class FKCellHeroCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellHeroRow

  private let groupedBackground = FKCellGroupedBackgroundView()
  private let rootStack = UIStackView()
  private let iconSlot = FKCellIconSlotView()
  private let titleLabel = UILabel()
  private let descriptionLabel = UILabel()
  private let separator = FKCellSeparatorLayout.makeDivider()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellHeroConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellHeroConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    if let icon = configuration.icon {
      iconSlot.apply(icon)
      iconSlot.isHidden = false
    } else {
      iconSlot.isHidden = true
    }

    titleLabel.text = configuration.title
    titleLabel.textAlignment = configuration.textAlignment
    descriptionLabel.text = configuration.description
    descriptionLabel.textAlignment = configuration.textAlignment

    groupedBackground.apply(nil)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = "\(configuration.title). \(configuration.description)"
  }

  public func configure(with viewModel: FKCellHeroRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    iconSlot.reset()
    titleLabel.text = nil
    descriptionLabel.text = nil
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    groupedBackground.translatesAutoresizingMaskIntoConstraints = false
    rootStack.axis = .vertical
    rootStack.alignment = .center
    rootStack.spacing = 12
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .title2)
    titleLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .boldSystemFont(ofSize: 22))
    titleLabel.numberOfLines = 0
    titleLabel.adjustsFontForContentSizeCategory = true

    descriptionLabel.font = .preferredFont(forTextStyle: .body)
    descriptionLabel.textColor = .secondaryLabel
    descriptionLabel.numberOfLines = 0
    descriptionLabel.adjustsFontForContentSizeCategory = true

    separator.translatesAutoresizingMaskIntoConstraints = false
    rootStack.addArrangedSubview(iconSlot)
    rootStack.addArrangedSubview(titleLabel)
    rootStack.addArrangedSubview(descriptionLabel)

    contentView.addSubview(groupedBackground)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      groupedBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
      groupedBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      groupedBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      groupedBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top + 8),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom - 8),

      iconSlot.widthAnchor.constraint(equalToConstant: 64),
      iconSlot.heightAnchor.constraint(equalToConstant: 64),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
