import FKCoreKit
import UIKit
@MainActor
public final class FKCellMonospaceBlockCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellMonospaceBlockRow
  public var onExpandTap: (() -> Void)?
  private let codeLabel = UILabel(); private let expandButton = UIButton(type: .system); private let separator = FKCellSeparatorLayout.makeDivider()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellMonospaceBlockConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellMonospaceBlockConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    codeLabel.text = configuration.codeText; codeLabel.numberOfLines = configuration.maxLines
    expandButton.isHidden = !configuration.showsExpand
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = .secondarySystemGroupedBackground
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
    accessibilityLabel = configuration.codeText
  }
  public func configure(with viewModel: FKCellMonospaceBlockRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onExpandTap = nil; codeLabel.text = nil; selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    codeLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular); codeLabel.numberOfLines = 4
    expandButton.setTitle("Expand", for: .normal); expandButton.addTarget(self, action: #selector(expandTapped), for: .touchUpInside)
    let col = UIStackView(arrangedSubviews: [codeLabel, expandButton]); col.axis = .vertical; col.spacing = 4
    col.translatesAutoresizingMaskIntoConstraints = false; separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(col); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      col.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      col.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      col.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      col.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      separator.leadingAnchor.constraint(equalTo: col.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
  @objc private func expandTapped() { onExpandTap?() }
}
