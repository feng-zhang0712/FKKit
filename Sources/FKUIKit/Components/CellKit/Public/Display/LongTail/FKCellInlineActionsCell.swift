import FKCoreKit
import UIKit
@MainActor
public final class FKCellInlineActionsCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellInlineActionsRow
  public var onActionTap: ((Int) -> Void)?
  private let actionsStack = UIStackView(); private let separator = FKCellSeparatorLayout.makeDivider()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellInlineActionsConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellInlineActionsConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    actionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    for (index, action) in configuration.actions.enumerated() {
      let button = UIButton(type: .system); button.setTitle(action.title, for: .normal)
      button.setTitleColor(action.isDestructive ? .systemRed : appearance.linkColor, for: .normal)
      button.tag = index; button.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
      actionsStack.addArrangedSubview(button)
    }
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
  }
  public func configure(with viewModel: FKCellInlineActionsRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onActionTap = nil; selectionStyle = .none }
  @objc private func actionTapped(_ sender: UIButton) { onActionTap?(sender.tag) }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    actionsStack.axis = .horizontal; actionsStack.distribution = .fillEqually; actionsStack.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(actionsStack); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      actionsStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      actionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      actionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      actionsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      actionsStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      separator.leadingAnchor.constraint(equalTo: actionsStack.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
