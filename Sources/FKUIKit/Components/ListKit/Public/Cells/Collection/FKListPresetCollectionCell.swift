import FKCoreKit
import UIKit

/// Collection preset cell sharing layout with ``FKListPresetTableCell``.
@MainActor
public final class FKListPresetCollectionCell: UICollectionViewCell, FKListCollectionCellConfigurable {
  public typealias Item = FKListPresetCellContext

  private let cardView = UIView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let textStack = UIStackView()
  private let mainStack = UIStackView()
  private var cardConstraints: [NSLayoutConstraint] = []

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    applyCardChrome(isEnabled: false)
  }

  public func configure(with item: FKListPresetCellContext) {
    applyCardChrome(isEnabled: item.displaysCardChrome)
    titleLabel.text = nil
    subtitleLabel.text = nil
    subtitleLabel.isHidden = true
    switch item.preset {
    case .text(let row):
      titleLabel.text = row.title
    case .subtitle(let row):
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
    case .icon(let row):
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
    case .switch(let row):
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
    case .checkbox(let row):
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
    case .disclosure(let row):
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
    case .customValue(let row):
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
    }
    titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: item.appearance.titleFont)
    subtitleLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: item.appearance.subtitleFont)
    titleLabel.textColor = item.appearance.titleColor
    subtitleLabel.textColor = item.appearance.subtitleColor
    accessibilityLabel = [titleLabel.text, subtitleLabel.text].compactMap { $0 }.joined(separator: ", ")
  }

  private func setup() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    cardView.backgroundColor = .secondarySystemGroupedBackground
    cardView.layer.cornerRadius = 12
    cardView.layer.masksToBounds = true
    cardView.translatesAutoresizingMaskIntoConstraints = false
    cardView.isHidden = true
    contentView.addSubview(cardView)

    titleLabel.numberOfLines = 0
    subtitleLabel.numberOfLines = 0
    textStack.axis = .vertical
    textStack.spacing = 2
    textStack.addArrangedSubview(titleLabel)
    textStack.addArrangedSubview(subtitleLabel)
    mainStack.axis = .horizontal
    mainStack.alignment = .center
    mainStack.translatesAutoresizingMaskIntoConstraints = false
    mainStack.addArrangedSubview(textStack)
    contentView.addSubview(mainStack)
    NSLayoutConstraint.activate([
      mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
      mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11),
      contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }

  private func applyCardChrome(isEnabled: Bool) {
    NSLayoutConstraint.deactivate(cardConstraints)
    cardConstraints.removeAll()
    cardView.isHidden = !isEnabled
    backgroundColor = isEnabled ? .clear : .systemBackground
    if isEnabled {
      let inset: CGFloat = 0
      cardConstraints = [
        cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset),
        cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
        cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
        cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset),
      ]
      NSLayoutConstraint.activate(cardConstraints)
    }
  }
}
