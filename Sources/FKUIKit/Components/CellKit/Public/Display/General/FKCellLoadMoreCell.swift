import FKCoreKit
import UIKit

/// Pagination load-more row with spinner (D-79).
@MainActor
public final class FKCellLoadMoreCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellLoadMoreRow

  /// Called on the main actor when the user taps the row.
  public var onTap: (() -> Void)?

  private let stack = UIStackView()
  private let spinner = UIActivityIndicatorView(style: .medium)
  private let titleLabel = UILabel()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellLoadMoreConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellLoadMoreConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.title
    if configuration.isLoading {
      spinner.startAnimating()
      spinner.isHidden = false
    } else {
      spinner.stopAnimating()
      spinner.isHidden = true
    }

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled && !configuration.isLoading
    alpha = configuration.isEnabled ? 1 : 0.5
    selectionStyle = .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellLoadMoreRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTap = nil
    spinner.stopAnimating()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textColor = .secondaryLabel
    titleLabel.adjustsFontForContentSizeCategory = true

    stack.addArrangedSubview(spinner)
    stack.addArrangedSubview(titleLabel)
    contentView.addSubview(stack)

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    contentView.addGestureRecognizer(tap)

    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      stack.heightAnchor.constraint(greaterThanOrEqualToConstant: FKCellLayoutMetrics.minimumRowHeight - 24),
    ])
  }

  @objc private func handleTap() {
    onTap?()
  }
}
