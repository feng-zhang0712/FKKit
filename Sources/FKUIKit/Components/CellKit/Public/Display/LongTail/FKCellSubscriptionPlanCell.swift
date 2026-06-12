import FKCoreKit
import UIKit
@MainActor
public final class FKCellSubscriptionPlanCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellSubscriptionPlanRow
  private let cardView = UIView(); private let titleLabel = UILabel(); private let priceLabel = UILabel()
  private let featuresStack = UIStackView(); private let checkView = UIImageView(); private let separator = FKCellSeparatorLayout.makeDivider()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellSubscriptionPlanConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellSubscriptionPlanConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    titleLabel.text = configuration.planName; priceLabel.text = configuration.priceText
    featuresStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    for feature in configuration.features {
      let label = UILabel(); label.font = .preferredFont(forTextStyle: .footnote); label.textColor = .secondaryLabel
      label.text = "• \(feature)"; featuresStack.addArrangedSubview(label)
    }
    checkView.isHidden = !configuration.isSelected
    cardView.layer.borderWidth = configuration.isSelected ? 2 : 1
    cardView.layer.borderColor = (configuration.isSelected ? UIColor.systemBlue : UIColor.separator).cgColor
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.planName
  }
  public func configure(with viewModel: FKCellSubscriptionPlanRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); titleLabel.text = nil; priceLabel.text = nil; checkView.isHidden = true; selectionStyle = .default }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear
    cardView.translatesAutoresizingMaskIntoConstraints = false; cardView.layer.cornerRadius = 12
    cardView.backgroundColor = .secondarySystemGroupedBackground
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    priceLabel.font = .preferredFont(forTextStyle: .title3)
    featuresStack.axis = .vertical; featuresStack.spacing = 4
    checkView.image = UIImage(systemName: "checkmark.circle.fill"); checkView.tintColor = .systemBlue
    checkView.translatesAutoresizingMaskIntoConstraints = false
    let header = UIStackView(arrangedSubviews: [titleLabel, checkView]); header.axis = .horizontal; header.alignment = .center
    let col = UIStackView(arrangedSubviews: [header, priceLabel, featuresStack]); col.axis = .vertical; col.spacing = 8
    col.translatesAutoresizingMaskIntoConstraints = false
    cardView.addSubview(col); separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(cardView); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      col.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
      col.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
      col.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
      col.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
      checkView.widthAnchor.constraint(equalToConstant: 24),
      separator.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
