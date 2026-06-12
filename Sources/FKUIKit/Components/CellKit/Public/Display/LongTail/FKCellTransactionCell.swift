import FKCoreKit
import UIKit
@MainActor
public final class FKCellTransactionCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellTransactionRow
  private let layout = FKCellStandardRowLayout()
  private let amountLabel = UILabel()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellTransactionConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellTransactionConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title); layout.contentStack.setSubtitle(configuration.subtitle)
    amountLabel.text = configuration.amountText
    amountLabel.font = .monospacedDigitSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)
    switch configuration.kind { case .credit: amountLabel.textColor = .systemGreen; case .debit: amountLabel.textColor = .systemRed; case .neutral: amountLabel.textColor = .label }
    layout.contentStack.setAccessoryViews([amountLabel])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = "\(configuration.title), \(configuration.amountText)"
  }
  public func configure(with viewModel: FKCellTransactionRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); layout.resetForReuse(); amountLabel.text = nil; selectionStyle = .none }
  private func commonInit() { backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none; layout.install(in: contentView) }
}
