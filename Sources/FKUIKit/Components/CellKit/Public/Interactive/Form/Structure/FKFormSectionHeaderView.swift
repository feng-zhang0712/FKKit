import UIKit

/// Bold form section header with optional secondary subtitle (X-10).
@MainActor
public final class FKFormSectionHeaderView: UITableViewHeaderFooterView {
  public static var reuseIdentifier: String { String(describing: Self.self) }

  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let stack = UIStackView()

  public override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies header title and subtitle.
  public func apply(
    _ configuration: FKFormSectionHeaderConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.title
    subtitleLabel.text = configuration.subtitle
    subtitleLabel.isHidden = configuration.subtitle?.isEmpty ?? true

    titleLabel.font = FKCellTextStyle(textStyle: .headline, weight: .bold)
      .resolvedFont(compatibleWith: traitCollection)
    subtitleLabel.font = appearance.subtitleTextStyle.resolvedFont(compatibleWith: traitCollection)
    subtitleLabel.textColor = appearance.secondaryLabelColor.resolvedColor(with: traitCollection)

    accessibilityLabel = [configuration.title, configuration.subtitle]
      .compactMap { value in
        guard let value, !value.isEmpty else { return nil }
        return value
      }
      .joined(separator: ", ")
    accessibilityTraits = [.header]
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    subtitleLabel.text = nil
    accessibilityLabel = nil
  }

  private func commonInit() {
    contentView.backgroundColor = .clear
    backgroundView = UIView()
    backgroundView?.backgroundColor = .clear

    stack.axis = .vertical
    stack.spacing = 4
    stack.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.numberOfLines = 0
    titleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.numberOfLines = 0
    subtitleLabel.adjustsFontForContentSizeCategory = true

    stack.addArrangedSubview(titleLabel)
    stack.addArrangedSubview(subtitleLabel)
    contentView.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
    ])
  }
}
