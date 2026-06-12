import FKCoreKit
import UIKit
@MainActor
public final class FKCellConflictCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellConflictRow
  private let layout = FKCellStandardRowLayout(); private let iconSlot = FKCellIconSlotView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellConflictConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellConflictConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    iconSlot.apply(FKCellIconContent(symbolName: "exclamationmark.triangle.fill"))
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.message); layout.contentStack.setSubtitle(configuration.detail)
    layout.contentStack.setAccessoryViews([])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.message
  }
  public func configure(with viewModel: FKCellConflictRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); iconSlot.reset(); layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none; layout.install(in: contentView) }
}
