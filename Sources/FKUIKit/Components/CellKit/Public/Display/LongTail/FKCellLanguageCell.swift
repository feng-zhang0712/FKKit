import FKCoreKit
import UIKit
@MainActor
public final class FKCellLanguageCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellLanguageRow
  private let layout = FKCellStandardRowLayout(); private let iconSlot = FKCellIconSlotView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellLanguageConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellLanguageConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    if let icon = configuration.flagIcon { iconSlot.apply(icon); layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth) }
    else { layout.contentStack.setLeadingContent(nil, width: 0) }
    layout.contentStack.setTitle(configuration.languageName); layout.contentStack.setSubtitle(configuration.nativeName)
    layout.accessoryHost.apply(.checkmark(isSelected: configuration.isSelected), appearance: appearance)
    layout.contentStack.setAccessoryViews([layout.accessoryHost])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = configuration.isEnabled ? .default : .none; accessibilityLabel = configuration.languageName
  }
  public func configure(with viewModel: FKCellLanguageRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); iconSlot.reset(); layout.resetForReuse(); selectionStyle = .default }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; layout.install(in: contentView) }
}
