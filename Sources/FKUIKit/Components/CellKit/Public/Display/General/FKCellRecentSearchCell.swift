import FKCoreKit
import UIKit

/// Recent search query row with delete affordance (D-67).
@MainActor
public final class FKCellRecentSearchCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellRecentSearchRow

  /// Called on the main actor when the user taps delete.
  public var onDelete: (() -> Void)?

  private let layout = FKCellStandardRowLayout()
  private let iconSlot = FKCellIconSlotView()
  private let deleteButton = UIButton(type: .system)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellRecentSearchConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellRecentSearchConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    iconSlot.apply(FKCellIconContent(symbolName: "clock"))
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.query)
    deleteButton.isHidden = !configuration.showsDeleteButton
    layout.contentStack.setAccessoryViews(configuration.showsDeleteButton ? [deleteButton] : [])

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.query
  }

  public func configure(with viewModel: FKCellRecentSearchRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onDelete = nil
    iconSlot.reset()
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    deleteButton.translatesAutoresizingMaskIntoConstraints = false
    deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
    deleteButton.accessibilityLabel = "Delete recent search"

    layout.install(in: contentView)
  }

  @objc private func handleDelete() {
    onDelete?()
  }
}
