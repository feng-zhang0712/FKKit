import UIKit

/// Collection section header supplementary view.
@MainActor
final class FKListCollectionSectionHeaderView: UICollectionReusableView {
  static let reuseIdentifier = "FKListCollectionSectionHeaderView"

  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let stack = UIStackView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    stack.axis = .vertical
    stack.spacing = 2
    stack.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0
    subtitleLabel.numberOfLines = 0
    stack.addArrangedSubview(titleLabel)
    stack.addArrangedSubview(subtitleLabel)
    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
    ])
    accessibilityTraits = .header
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(header: FKListSectionHeaderFooter, appearance: FKListAppearanceConfiguration) {
    switch header {
    case .title(let title):
      titleLabel.text = title
      subtitleLabel.isHidden = true
      accessibilityLabel = title
    case .subtitle(let title, let subtitle):
      titleLabel.text = title
      subtitleLabel.text = subtitle
      subtitleLabel.isHidden = subtitle?.isEmpty != false
      accessibilityLabel = [title, subtitle].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    case .custom:
      break
    }
    titleLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: appearance.sectionHeaderFont)
    titleLabel.textColor = appearance.sectionHeaderColor
    subtitleLabel.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: appearance.subtitleFont)
    subtitleLabel.textColor = appearance.subtitleColor
  }
}
