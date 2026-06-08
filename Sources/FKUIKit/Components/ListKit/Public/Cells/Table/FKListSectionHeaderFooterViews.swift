import UIKit

/// Self-sizing section header with title and optional subtitle.
@MainActor
final class FKListSectionHeaderView: UITableViewHeaderFooterView {
  static let reuseIdentifier = "FKListSectionHeaderView"

  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let stack = UIStackView()

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    stack.axis = .vertical
    stack.spacing = 2
    stack.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0
    subtitleLabel.numberOfLines = 0
    stack.addArrangedSubview(titleLabel)
    stack.addArrangedSubview(subtitleLabel)
    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
    ])
    accessibilityTraits = .header
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(title: String, subtitle: String?, appearance: FKListAppearanceConfiguration) {
    titleLabel.text = title
    titleLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: appearance.sectionHeaderFont)
    titleLabel.textColor = appearance.sectionHeaderColor
    subtitleLabel.text = subtitle
    subtitleLabel.isHidden = subtitle?.isEmpty != false
    subtitleLabel.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: appearance.subtitleFont)
    subtitleLabel.textColor = appearance.subtitleColor
    accessibilityLabel = [title, subtitle].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
  }
}

/// Simple section footer label.
@MainActor
final class FKListSectionFooterView: UITableViewHeaderFooterView {
  static let reuseIdentifier = "FKListSectionFooterView"

  private let label = UILabel()

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(text: String, appearance: FKListAppearanceConfiguration) {
    label.text = text
    label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: appearance.sectionHeaderFont)
    label.textColor = appearance.sectionHeaderColor
  }
}
