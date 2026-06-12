import FKCoreKit
import UIKit
@MainActor
public final class FKCellLiveBadgeCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellLiveBadgeRow
  private let layout = FKCellStandardRowLayout(); private let livePill = FKStatusPill(title: "LIVE", style: .error)
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellLiveBadgeConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellLiveBadgeConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title)
    livePill.title = configuration.liveBadgeText
    layout.contentStack.setAccessoryViews([livePill])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellLiveBadgeRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none; layout.install(in: contentView) }
}
