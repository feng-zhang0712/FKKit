import FKCoreKit
import UIKit

/// Compact zero-results empty state row (D-88).
@MainActor
public final class FKCellZeroResultsCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellZeroResultsRow

  private let stack = UIStackView()
  private let iconView = UIImageView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellZeroResultsConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellZeroResultsConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    iconView.image = UIImage(systemName: configuration.iconSymbolName)
    titleLabel.text = configuration.title
    if let subtitle = configuration.subtitle, !subtitle.isEmpty {
      subtitleLabel.text = subtitle
      subtitleLabel.isHidden = false
    } else {
      subtitleLabel.isHidden = true
    }

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled
    selectionStyle = .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellZeroResultsRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    iconView.image = nil
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

    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.tintColor = .secondaryLabel
    iconView.contentMode = .scaleAspectFit

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textAlignment = .center
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 0

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.numberOfLines = 0
    subtitleLabel.isHidden = true

    stack.addArrangedSubview(iconView)
    stack.addArrangedSubview(titleLabel)
    stack.addArrangedSubview(subtitleLabel)
    contentView.addSubview(stack)

    NSLayoutConstraint.activate([
      iconView.widthAnchor.constraint(equalToConstant: 40),
      iconView.heightAnchor.constraint(equalToConstant: 40),

      stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
    ])
  }
}
