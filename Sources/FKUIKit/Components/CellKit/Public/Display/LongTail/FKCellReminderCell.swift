import FKCoreKit
import UIKit
@MainActor
public final class FKCellReminderCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellReminderRow
  private let layout = FKCellStandardRowLayout(); private let iconSlot = FKCellIconSlotView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellReminderConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellReminderConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    iconSlot.apply(FKCellIconContent(symbolName: "bell"))
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.title)
    layout.accessoryHost.apply(.value(configuration.timeText), appearance: appearance)
    layout.contentStack.setAccessoryViews([layout.accessoryHost])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellReminderRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); iconSlot.reset(); layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none; layout.install(in: contentView) }
}
