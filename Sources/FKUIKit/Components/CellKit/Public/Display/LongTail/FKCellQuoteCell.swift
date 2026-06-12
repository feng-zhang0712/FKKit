import FKCoreKit
import UIKit
@MainActor
public final class FKCellQuoteCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellQuoteRow
  private let accentBar = UIView(); private let quoteLabel = UILabel(); private let attributionLabel = UILabel(); private let separator = FKCellSeparatorLayout.makeDivider()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellQuoteConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellQuoteConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    quoteLabel.text = configuration.quoteText
    if configuration.isItalic { quoteLabel.font = .italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize) }
    if let attr = configuration.attribution { attributionLabel.text = attr; attributionLabel.isHidden = false } else { attributionLabel.isHidden = true }
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
    accessibilityLabel = configuration.quoteText
  }
  public func configure(with viewModel: FKCellQuoteRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); quoteLabel.text = nil; attributionLabel.text = nil; selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    accentBar.backgroundColor = .systemBlue; accentBar.translatesAutoresizingMaskIntoConstraints = false
    quoteLabel.numberOfLines = 0; quoteLabel.font = .preferredFont(forTextStyle: .body)
    attributionLabel.font = .preferredFont(forTextStyle: .caption1); attributionLabel.textColor = .secondaryLabel
    let col = UIStackView(arrangedSubviews: [quoteLabel, attributionLabel]); col.axis = .vertical; col.spacing = 4
    col.translatesAutoresizingMaskIntoConstraints = false; separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(accentBar); contentView.addSubview(col); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      accentBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      accentBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      accentBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      accentBar.widthAnchor.constraint(equalToConstant: 3),
      col.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
      col.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      col.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      col.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      separator.leadingAnchor.constraint(equalTo: col.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
