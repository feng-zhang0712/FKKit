import FKCoreKit
import UIKit
@MainActor
public final class FKCellDeviceCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellDeviceRow
  private let layout = FKCellStandardRowLayout(); private let iconSlot = FKCellIconSlotView(); private let statusPill = FKStatusPill()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellDeviceConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellDeviceConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance); iconSlot.apply(FKCellIconContent(symbolName: "iphone"))
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.deviceName)
    statusPill.title = configuration.statusText; statusPill.style = configuration.statusStyle
    layout.contentStack.setAccessoryViews([statusPill])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.deviceName
  }
  public func configure(with viewModel: FKCellDeviceRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); iconSlot.reset(); layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none; layout.install(in: contentView) }
}
