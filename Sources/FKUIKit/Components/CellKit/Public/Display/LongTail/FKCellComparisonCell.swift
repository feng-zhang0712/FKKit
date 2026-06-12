import FKCoreKit
import UIKit
@MainActor
public final class FKCellComparisonCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellComparisonRow
  private let leftColumn = UIStackView(); private let rightColumn = UIStackView(); private let divider = FKDivider()
  private let separator = FKCellSeparatorLayout.makeDivider()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellComparisonConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellComparisonConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    configureColumn(leftColumn, title: configuration.leftTitle, value: configuration.leftValue)
    configureColumn(rightColumn, title: configuration.rightTitle, value: configuration.rightValue)
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
  }
  public func configure(with viewModel: FKCellComparisonRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); selectionStyle = .none }
  private func configureColumn(_ column: UIStackView, title: String, value: String) {
    column.arrangedSubviews.forEach { $0.removeFromSuperview() }
    let titleLabel = UILabel(); titleLabel.font = .preferredFont(forTextStyle: .caption1); titleLabel.textColor = .secondaryLabel; titleLabel.text = title
    let valueLabel = UILabel(); valueLabel.font = .preferredFont(forTextStyle: .body); valueLabel.text = value
    column.addArrangedSubview(titleLabel); column.addArrangedSubview(valueLabel)
  }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    leftColumn.axis = .vertical; rightColumn.axis = .vertical; leftColumn.spacing = 2; rightColumn.spacing = 2
    divider.translatesAutoresizingMaskIntoConstraints = false; separator.translatesAutoresizingMaskIntoConstraints = false
    let row = UIStackView(arrangedSubviews: [leftColumn, divider, rightColumn]); row.axis = .horizontal; row.spacing = 12; row.distribution = .fillEqually
    row.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview(row); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      divider.widthAnchor.constraint(equalToConstant: 1),
      separator.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
