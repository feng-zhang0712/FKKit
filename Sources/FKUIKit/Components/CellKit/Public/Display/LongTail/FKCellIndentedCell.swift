import FKCoreKit
import UIKit
@MainActor
public final class FKCellIndentedCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellIndentedRow
  private let layout = FKCellStandardRowLayout()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellIndentedConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellIndentedConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    let indent = CGFloat(max(0, configuration.indentLevel)) * 16
    layout.contentStack.setLeadingContent(nil, width: indent)
    layout.contentStack.setTitle(configuration.title); layout.contentStack.setSubtitle(configuration.subtitle)
    layout.contentStack.setAccessoryViews([])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = configuration.isEnabled ? .default : .none; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellIndentedRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); layout.resetForReuse(); selectionStyle = .default }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; layout.install(in: contentView) }
}
