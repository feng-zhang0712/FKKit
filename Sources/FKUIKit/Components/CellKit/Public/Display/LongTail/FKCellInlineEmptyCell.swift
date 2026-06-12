import FKCoreKit
import UIKit
@MainActor
public final class FKCellInlineEmptyCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellInlineEmptyRow
  public var onActionTap: (() -> Void)?
  private let emptyView = FKEmptyStateView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellInlineEmptyConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellInlineEmptyConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    var content = FKEmptyStateContentConfiguration()
    content.title = configuration.title
    content.description = configuration.message
    content.image = FKEmptyStateImageContent.systemSymbol(configuration.iconSymbolName, pointSize: 32)

    var layoutConfig = FKEmptyStateLayoutConfiguration()
    layoutConfig.density = .compact
    layoutConfig.contentAlignment = .center

    var actions = FKEmptyStateActionSet()
    if let actionTitle = configuration.actionTitle {
      actions.primary = FKEmptyStateAction(id: "inlineEmptyAction", title: actionTitle, kind: .primary)
    }

    emptyView.apply(
      FKEmptyStateConfiguration(
        content: content,
        layout: layoutConfig,
        actions: actions
      )
    )
    emptyView.actionHandler = { [weak self] action in
      guard action.id == "inlineEmptyAction" else { return }
      self?.onActionTap?()
    }
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
    accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellInlineEmptyRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onActionTap = nil; selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    emptyView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: contentView.topAnchor),
      emptyView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      emptyView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      emptyView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      emptyView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
    ])
  }
}
