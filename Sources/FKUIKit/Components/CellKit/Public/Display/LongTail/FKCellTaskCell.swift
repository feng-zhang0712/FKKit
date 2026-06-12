import FKCoreKit
import UIKit
@MainActor
public final class FKCellTaskCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellTaskRow
  private let layout = FKCellStandardRowLayout()
  private let statusIcon = UIImageView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellTaskConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellTaskConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    statusIcon.image = UIImage(systemName: configuration.isCompleted ? "checkmark.circle.fill" : "circle")
    statusIcon.tintColor = configuration.isCompleted ? .systemGreen : .tertiaryLabel
    layout.contentStack.setLeadingContent(statusIcon, width: 24)
    layout.contentStack.setTitle(configuration.title)
    if let due = configuration.dueDateText {
      layout.contentStack.setSubtitle(due)
      layout.contentStack.subtitleLabel.textColor = configuration.isOverdue ? .systemRed : appearance.secondaryLabelColor
    } else { layout.contentStack.setSubtitle(nil) }
    if configuration.isCompleted {
      let attr = NSAttributedString(string: configuration.title, attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
      layout.contentStack.titleLabel.attributedText = attr
    }
    layout.contentStack.setAccessoryViews([])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellTaskRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); layout.resetForReuse(); statusIcon.image = nil; selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    statusIcon.contentMode = .scaleAspectFit; statusIcon.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([statusIcon.widthAnchor.constraint(equalToConstant: 24), statusIcon.heightAnchor.constraint(equalToConstant: 24)])
    layout.install(in: contentView)
  }
}
