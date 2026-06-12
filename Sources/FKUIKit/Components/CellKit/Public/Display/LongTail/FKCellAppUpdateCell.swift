import FKCoreKit
import UIKit
@MainActor
public final class FKCellAppUpdateCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellAppUpdateRow
  private let layout = FKCellStandardRowLayout(); private let badgePill = FKStatusPill(title: "Update", style: .info)
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellAppUpdateConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellAppUpdateConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.versionText); layout.contentStack.setSubtitle(configuration.releaseNotes)
    if configuration.showsUpdateBadge { layout.contentStack.setAccessoryViews([badgePill]) } else { layout.contentStack.setAccessoryViews([]) }
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = configuration.isEnabled ? .default : .none; accessibilityLabel = configuration.versionText
  }
  public func configure(with viewModel: FKCellAppUpdateRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); layout.resetForReuse(); selectionStyle = .default }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; layout.install(in: contentView) }
}
