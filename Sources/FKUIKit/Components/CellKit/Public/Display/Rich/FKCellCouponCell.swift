import FKCoreKit
import UIKit

/// Coupon row with accent bar, amount, rules, and optional action (D-31).
@MainActor
public final class FKCellCouponCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellCouponRow

  /// Called when the user taps the optional action button.
  public var onActionTapped: (() -> Void)?

  private let groupedBackground = FKCellGroupedBackgroundView()
  private let rootStack = UIStackView()
  private let contentRow = UIStackView()
  private let accentBar = UIView()
  private let textStack = UIStackView()
  private let amountLabel = UILabel()
  private let titleLabel = UILabel()
  private let rulesLabel = UILabel()
  private let actionButton = UIButton(type: .system)
  private let separator = FKCellSeparatorLayout.makeDivider()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellCouponConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellCouponConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    accentBar.backgroundColor = configuration.accentColor
    amountLabel.text = configuration.amountText
    titleLabel.text = configuration.title
    rulesLabel.text = configuration.rulesText

    if let actionTitle = configuration.actionTitle {
      actionButton.setTitle(actionTitle, for: .normal)
      actionButton.isHidden = false
    } else {
      actionButton.isHidden = true
    }

    groupedBackground.apply(nil)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    selectionStyle = configuration.actionTitle == nil ? .default : .none
    accessibilityLabel = "\(configuration.title), \(configuration.amountText)"
  }

  public func configure(with viewModel: FKCellCouponRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onActionTapped = nil
    amountLabel.text = nil
    titleLabel.text = nil
    rulesLabel.text = nil
    actionButton.isHidden = true
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    groupedBackground.translatesAutoresizingMaskIntoConstraints = false
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    contentRow.axis = .horizontal
    contentRow.alignment = .center
    contentRow.spacing = 12

    accentBar.translatesAutoresizingMaskIntoConstraints = false
    accentBar.layer.cornerRadius = 2
    accentBar.layer.cornerCurve = .continuous

    textStack.axis = .vertical
    textStack.spacing = 4
    textStack.alignment = .leading

    amountLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .boldSystemFont(ofSize: 24))
    amountLabel.adjustsFontForContentSizeCategory = true

    titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .boldSystemFont(ofSize: 17))
    titleLabel.numberOfLines = 2
    titleLabel.adjustsFontForContentSizeCategory = true

    rulesLabel.font = .preferredFont(forTextStyle: .footnote)
    rulesLabel.textColor = .secondaryLabel
    rulesLabel.numberOfLines = 0
    rulesLabel.adjustsFontForContentSizeCategory = true

    actionButton.contentHorizontalAlignment = .leading
    actionButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
    actionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)
    actionButton.isHidden = true

    separator.translatesAutoresizingMaskIntoConstraints = false
    textStack.addArrangedSubview(amountLabel)
    textStack.addArrangedSubview(titleLabel)
    textStack.addArrangedSubview(rulesLabel)
    contentRow.addArrangedSubview(accentBar)
    contentRow.addArrangedSubview(textStack)
    rootStack.addArrangedSubview(contentRow)
    rootStack.addArrangedSubview(actionButton)

    contentView.addSubview(groupedBackground)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      groupedBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
      groupedBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      groupedBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      groupedBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      accentBar.widthAnchor.constraint(equalToConstant: 4),
      accentBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  @objc private func handleActionTap() {
    onActionTapped?()
  }
}
