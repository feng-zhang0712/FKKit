import FKCoreKit
import UIKit

/// Warning card with body copy and primary action link (D-09).
@MainActor
public final class FKCellAlertActionCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellAlertActionRow

  public var onPrimaryActionTapped: ((FKCellActionLink) -> Void)?

  private let groupedBackground = FKCellGroupedBackgroundView()
  private let rootStack = UIStackView()
  private let titleRow = UIStackView()
  private let titleLabel = UILabel()
  private let warningIcon = UIImageView()
  private let bodyLabel = UILabel()
  private let footerSeparator = FKCellSeparatorLayout.makeDivider()
  private let actionButton = UIButton(type: .system)
  private let bottomSeparator = FKCellSeparatorLayout.makeDivider()
  private var storedAction: FKCellActionLink?
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellAlertActionConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellAlertActionConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    self.appearance = appearance
    storedAction = configuration.primaryAction

    titleLabel.text = configuration.title
    bodyLabel.text = configuration.body

    if let symbol = configuration.warningSymbolName {
      warningIcon.image = UIImage(systemName: symbol)
      warningIcon.tintColor = .systemOrange
      warningIcon.isHidden = false
    } else {
      warningIcon.isHidden = true
    }

    let linkColor = appearance.linkColor.resolvedColor(with: traitCollection)
    actionButton.setTitle(configuration.primaryAction.title, for: .normal)
    actionButton.setTitleColor(linkColor, for: .normal)

    groupedBackground.apply(nil)
    FKCellSeparatorLayout.updateVisibility(
      divider: bottomSeparator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellAlertActionRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onPrimaryActionTapped = nil
    storedAction = nil
    titleLabel.text = nil
    bodyLabel.text = nil
    warningIcon.image = nil
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    groupedBackground.translatesAutoresizingMaskIntoConstraints = false
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    titleRow.axis = .horizontal
    titleRow.alignment = .center
    titleRow.spacing = 8
    titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .boldSystemFont(ofSize: 17))
    titleLabel.numberOfLines = 0
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

    warningIcon.contentMode = .scaleAspectFit
    warningIcon.setContentHuggingPriority(.required, for: .horizontal)
    NSLayoutConstraint.activate([
      warningIcon.widthAnchor.constraint(equalToConstant: 20),
      warningIcon.heightAnchor.constraint(equalToConstant: 20),
    ])

    bodyLabel.font = .preferredFont(forTextStyle: .body)
    bodyLabel.textColor = .secondaryLabel
    bodyLabel.numberOfLines = 0

    footerSeparator.translatesAutoresizingMaskIntoConstraints = false
    bottomSeparator.translatesAutoresizingMaskIntoConstraints = false
    actionButton.contentHorizontalAlignment = .leading
    actionButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
    actionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)

    titleRow.addArrangedSubview(titleLabel)
    titleRow.addArrangedSubview(warningIcon)
    rootStack.addArrangedSubview(titleRow)
    rootStack.addArrangedSubview(bodyLabel)

    contentView.addSubview(groupedBackground)
    contentView.addSubview(rootStack)
    contentView.addSubview(footerSeparator)
    contentView.addSubview(actionButton)
    contentView.addSubview(bottomSeparator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      groupedBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
      groupedBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      groupedBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      groupedBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),

      footerSeparator.topAnchor.constraint(equalTo: rootStack.bottomAnchor, constant: 12),
      footerSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      footerSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

      actionButton.topAnchor.constraint(equalTo: footerSeparator.bottomAnchor, constant: 12),
      actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      bottomSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      bottomSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      bottomSeparator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  @objc private func handleActionTap() {
    guard let action = storedAction else { return }
    onPrimaryActionTapped?(action)
  }
}
