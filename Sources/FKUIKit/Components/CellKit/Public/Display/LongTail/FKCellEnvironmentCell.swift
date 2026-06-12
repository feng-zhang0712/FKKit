import FKCoreKit
import UIKit
@MainActor
public final class FKCellEnvironmentCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellEnvironmentRow
  private let layout = FKCellStandardRowLayout(); private let dotView = UIView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellEnvironmentConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellEnvironmentConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    dotView.backgroundColor = configuration.dotColor
    layout.contentStack.setLeadingContent(dotView, width: 12)
    layout.contentStack.setTitle(configuration.name)
    layout.accessoryHost.apply(.value(configuration.token), appearance: appearance)
    layout.contentStack.setAccessoryViews([layout.accessoryHost])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.name
  }
  public func configure(with viewModel: FKCellEnvironmentRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    dotView.layer.cornerRadius = 4; dotView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([dotView.widthAnchor.constraint(equalToConstant: 8), dotView.heightAnchor.constraint(equalToConstant: 8)])
    layout.install(in: contentView)
  }
}
