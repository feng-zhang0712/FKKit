import FKCoreKit
import UIKit
@MainActor
public final class FKCellPollResultCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellPollResultRow
  private let titleLabel = UILabel(); private let percentLabel = UILabel(); private let progressBar = FKProgressBar()
  private let separator = FKCellSeparatorLayout.makeDivider()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellPollResultConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellPollResultConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    titleLabel.text = configuration.optionTitle
    percentLabel.text = configuration.percentText ?? "\(Int(configuration.percent * 100))%"
    progressBar.setProgress(configuration.percent, animated: false)
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
    accessibilityLabel = "\(configuration.optionTitle), \(percentLabel.text ?? "")"
  }
  public func configure(with viewModel: FKCellPollResultRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); titleLabel.text = nil; percentLabel.text = nil; progressBar.setProgress(0, animated: false); selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    titleLabel.font = .preferredFont(forTextStyle: .body); percentLabel.font = .preferredFont(forTextStyle: .footnote)
    percentLabel.textColor = .secondaryLabel; progressBar.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false
    let header = UIStackView(arrangedSubviews: [titleLabel, percentLabel]); header.axis = .horizontal
    let col = UIStackView(arrangedSubviews: [header, progressBar]); col.axis = .vertical; col.spacing = 6
    col.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(col); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      col.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      col.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      col.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      col.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      progressBar.heightAnchor.constraint(equalToConstant: 6),
      separator.leadingAnchor.constraint(equalTo: col.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
