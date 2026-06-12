import FKCoreKit
import UIKit
@MainActor
public final class FKCellShortcutGridCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellShortcutGridRow
  public var onItemTap: ((Int) -> Void)?
  private let gridStack = UIStackView(); private let separator = FKCellSeparatorLayout.makeDivider()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellShortcutGridConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellShortcutGridConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    let columns = configuration.columns
    var rowStack: UIStackView? = nil
    for (index, item) in configuration.items.enumerated() {
      if index % columns == 0 {
        rowStack = UIStackView(); rowStack?.axis = .horizontal; rowStack?.distribution = .fillEqually; rowStack?.spacing = 8
        gridStack.addArrangedSubview(rowStack!)
      }
      let button = UIButton(type: .system); button.setTitle(item.title, for: .normal)
      button.setImage(UIImage(systemName: item.icon.symbolName ?? "square.grid.2x2"), for: .normal)
      button.tag = index; button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
      rowStack?.addArrangedSubview(button)
    }
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
  }
  public func configure(with viewModel: FKCellShortcutGridRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onItemTap = nil; selectionStyle = .none }
  @objc private func itemTapped(_ sender: UIButton) { onItemTap?(sender.tag) }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    gridStack.axis = .vertical; gridStack.spacing = 8; gridStack.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(gridStack); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      gridStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      gridStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      gridStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      gridStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      separator.leadingAnchor.constraint(equalTo: gridStack.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
