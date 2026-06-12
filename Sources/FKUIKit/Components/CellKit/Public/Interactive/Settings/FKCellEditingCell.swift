import FKCoreKit
import UIKit
@MainActor
public final class FKCellEditingCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellEditingRow
  private let layout = FKCellStandardRowLayout()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellEditingConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellEditingConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title); layout.contentStack.setSubtitle(configuration.subtitle)
    layout.contentStack.setAccessoryViews([])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    showsReorderControl = configuration.showsReorderControl
    selectionStyle = .default; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellEditingRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); layout.resetForReuse(); showsReorderControl = false; selectionStyle = .default }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; layout.install(in: contentView) }
}
