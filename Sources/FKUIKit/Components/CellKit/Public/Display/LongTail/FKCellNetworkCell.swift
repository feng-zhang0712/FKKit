import FKCoreKit
import UIKit
@MainActor
public final class FKCellNetworkCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellNetworkRow
  private let layout = FKCellStandardRowLayout(); private let iconSlot = FKCellIconSlotView(); private let statusPill = FKStatusPill()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellNetworkConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellNetworkConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance); iconSlot.apply(FKCellIconContent(symbolName: "wifi"))
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.networkName)
    statusPill.title = configuration.statusText; statusPill.style = configuration.statusStyle
    layout.contentStack.setAccessoryViews([statusPill])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.networkName
  }
  public func configure(with viewModel: FKCellNetworkRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); iconSlot.reset(); layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none; layout.install(in: contentView) }
}
