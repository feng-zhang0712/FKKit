import FKCoreKit
import UIKit

/// Centered hero description card for settings-style sections (D-06).
@MainActor
public final class FKCellHeroCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellHeroRow

  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  private let rootStack = UIStackView()
  private let heroIconView = UIImageView()
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
      applyHeroIcon(icon)
      heroIconView.isHidden = false
    } else {
      heroIconView.image = nil
      heroIconView.isHidden = true
    }

    titleLabel.text = configuration.title
    titleLabel.textAlignment = configuration.textAlignment
    descriptionLabel.text = configuration.description
    descriptionLabel.textAlignment = configuration.textAlignment

    groupedBackgroundHost.apply(nil, in: contentView)
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
    heroIconView.image = nil
    heroIconView.isHidden = true
    titleLabel.text = nil
    descriptionLabel.text = nil
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
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

    heroIconView.translatesAutoresizingMaskIntoConstraints = false
    heroIconView.contentMode = .scaleAspectFit
    heroIconView.setContentHuggingPriority(.required, for: .horizontal)
    heroIconView.setContentHuggingPriority(.required, for: .vertical)

    separator.translatesAutoresizingMaskIntoConstraints = false
    rootStack.addArrangedSubview(heroIconView)
    rootStack.addArrangedSubview(titleLabel)
    rootStack.addArrangedSubview(descriptionLabel)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top + 8),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom - 8),

      heroIconView.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.heroIconSize),
      heroIconView.heightAnchor.constraint(equalToConstant: FKCellLayoutMetrics.heroIconSize),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  private func applyHeroIcon(_ content: FKCellIconContent) {
    if let image = content.image {
      heroIconView.image = image
      heroIconView.tintColor = nil
      return
    }

    guard let symbolName = content.symbolName else {
      heroIconView.image = nil
      return
    }

    let pointSize = FKCellLayoutMetrics.heroIconSize * 0.875
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
    heroIconView.image = UIImage(systemName: symbolName, withConfiguration: symbolConfig)
    heroIconView.tintColor = content.configuration.appearance.defaultTintColor
  }
}
