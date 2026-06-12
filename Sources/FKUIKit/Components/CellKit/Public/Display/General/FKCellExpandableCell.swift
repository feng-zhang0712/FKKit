import FKCoreKit
import UIKit

/// FAQ-style expandable row with collapsible body (D-64, D-65).
@MainActor
public final class FKCellExpandableCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellExpandableRow

  private let layout = FKCellStandardRowLayout()
  private let bodyLabel = UILabel()
  private let chevronView = UIImageView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellExpandableConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellExpandableConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title)

    let symbol = configuration.isExpanded ? "chevron.up" : "chevron.down"
    chevronView.image = UIImage(systemName: symbol)
    layout.contentStack.setAccessoryViews([chevronView])

    bodyLabel.text = configuration.body
    bodyLabel.isHidden = !configuration.isExpanded || configuration.body?.isEmpty ?? true

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.title
    accessibilityTraits = [.button]
  }

  public func configure(with viewModel: FKCellExpandableRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    bodyLabel.text = nil
    bodyLabel.isHidden = true
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    chevronView.translatesAutoresizingMaskIntoConstraints = false
    chevronView.tintColor = .tertiaryLabel
    chevronView.setContentHuggingPriority(.required, for: .horizontal)

    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
    bodyLabel.numberOfLines = 0
    bodyLabel.font = .preferredFont(forTextStyle: .body)
    bodyLabel.textColor = .secondaryLabel
    bodyLabel.isHidden = true

    layout.install(in: contentView)
    contentView.addSubview(bodyLabel)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      bodyLabel.topAnchor.constraint(equalTo: layout.contentStack.bottomAnchor, constant: 4),
      bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -insets.bottom),
    ])
  }
}
