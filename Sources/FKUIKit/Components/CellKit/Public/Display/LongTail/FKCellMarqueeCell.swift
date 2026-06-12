import FKCoreKit
import UIKit
@MainActor
public final class FKCellMarqueeCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellMarqueeRow
  private let marquee = FKMarqueeLabel(); private let separator = FKCellSeparatorLayout.makeDivider()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellMarqueeConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellMarqueeConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    marquee.text = configuration.text
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none; accessibilityLabel = configuration.text
  }
  public func configure(with viewModel: FKCellMarqueeRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); marquee.text = ""; selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    marquee.translatesAutoresizingMaskIntoConstraints = false; separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(marquee); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      marquee.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      marquee.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      marquee.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      marquee.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      marquee.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      separator.leadingAnchor.constraint(equalTo: marquee.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
