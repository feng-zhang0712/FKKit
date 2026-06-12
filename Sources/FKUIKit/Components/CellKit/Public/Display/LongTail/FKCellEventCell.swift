import FKCoreKit
import UIKit

/// Calendar event row with date block and accent bar (D-51).
@MainActor
public final class FKCellEventCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellEventRow

  private let layout = FKCellStandardRowLayout()
  private let dateBlock = UIStackView()
  private let monthLabel = UILabel()
  private let dayLabel = UILabel()
  private let accentBar = UIView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellEventConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellEventConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    monthLabel.text = configuration.monthText.uppercased()
    dayLabel.text = configuration.dayText
    accentBar.backgroundColor = configuration.accentColor

    let dateContainer = UIView()
    dateContainer.translatesAutoresizingMaskIntoConstraints = false
    dateBlock.axis = .vertical
    dateBlock.alignment = .center
    dateBlock.spacing = 0
    dateBlock.addArrangedSubview(monthLabel)
    dateBlock.addArrangedSubview(dayLabel)
    dateContainer.addSubview(dateBlock)
    dateContainer.addSubview(accentBar)
    NSLayoutConstraint.activate([
      dateBlock.topAnchor.constraint(equalTo: dateContainer.topAnchor),
      dateBlock.leadingAnchor.constraint(equalTo: dateContainer.leadingAnchor),
      dateBlock.trailingAnchor.constraint(equalTo: dateContainer.trailingAnchor),
      accentBar.leadingAnchor.constraint(equalTo: dateContainer.leadingAnchor),
      accentBar.trailingAnchor.constraint(equalTo: dateContainer.trailingAnchor),
      accentBar.bottomAnchor.constraint(equalTo: dateContainer.bottomAnchor),
      accentBar.heightAnchor.constraint(equalToConstant: 3),
      dateBlock.bottomAnchor.constraint(equalTo: accentBar.topAnchor, constant: -4),
      dateContainer.widthAnchor.constraint(equalToConstant: 44),
    ])

    layout.contentStack.setLeadingContent(dateContainer, width: 44)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.subtitle)
    layout.contentStack.setAccessoryViews([])

    layout.applyChrome(
      .init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy,
            isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled),
      to: self
    )
    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellEventRow) { apply(viewModel.configuration) }

  public override func prepareForReuse() {
    super.prepareForReuse()
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    monthLabel.font = .preferredFont(forTextStyle: .caption2)
    monthLabel.textColor = .secondaryLabel
    dayLabel.font = .preferredFont(forTextStyle: .title2).withWeight(.semibold)
    accentBar.translatesAutoresizingMaskIntoConstraints = false
    dateBlock.translatesAutoresizingMaskIntoConstraints = false
    layout.install(in: contentView)
  }
}

private extension UIFont {
  func withWeight(_ weight: UIFont.Weight) -> UIFont {
    UIFont(descriptor: fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]]), size: pointSize)
  }
}
