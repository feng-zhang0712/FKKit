import FKCoreKit
import UIKit

/// Rich text card with optional status line and footer link (D-08).
@MainActor
public final class FKCellStatusDetailCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellStatusDetailRow

  public var onBodyLinkTapped: ((FKCellLinkRange) -> Void)?
  public var onFooterActionTapped: ((FKCellActionLink) -> Void)?

  private let groupedBackground = FKCellGroupedBackgroundView()
  private let rootStack = UIStackView()
  private let headerRow = UIStackView()
  private let iconSlot = FKCellIconSlotView()
  private let titleStack = UIStackView()
  private let titleLabel = UILabel()
  private let statusLabel = UILabel()
  private let bodyView = FKCellLinkTextView()
  private let footerStack = UIStackView()
  private let footerSeparator = FKCellSeparatorLayout.makeDivider()
  private let footerButton = UIButton(type: .system)
  private let bottomSeparator = FKCellSeparatorLayout.makeDivider()
  private var contentBottomConstraint: NSLayoutConstraint?
  private var footerBottomConstraint: NSLayoutConstraint?
  private var storedFooterAction: FKCellActionLink?
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellStatusDetailConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellStatusDetailConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    self.appearance = appearance
    storedFooterAction = configuration.footerAction

    if let icon = configuration.leadingIcon {
      iconSlot.apply(icon)
      iconSlot.isHidden = false
    } else {
      iconSlot.isHidden = true
    }

    titleLabel.text = configuration.title
    if let status = configuration.statusText {
      statusLabel.text = status
      statusLabel.textColor = configuration.statusColor
      statusLabel.isHidden = false
    } else {
      statusLabel.isHidden = true
    }

    let bodyFont = appearance.subtitleTextStyle.resolvedFont(compatibleWith: traitCollection)
    let bodyColor = appearance.secondaryLabelColor.resolvedColor(with: traitCollection)
    let linkColor = appearance.linkColor.resolvedColor(with: traitCollection)
    bodyView.apply(
      text: configuration.body,
      linkRanges: configuration.bodyLinkRanges,
      font: bodyFont,
      textColor: bodyColor,
      linkColor: linkColor
    )

    if let footer = configuration.footerAction {
      footerButton.setTitle(footer.title, for: .normal)
      footerButton.setTitleColor(linkColor, for: .normal)
      footerStack.isHidden = false
      footerSeparator.isHidden = !configuration.separatorBeforeFooter
      contentBottomConstraint?.isActive = false
      footerBottomConstraint?.isActive = true
    } else {
      footerStack.isHidden = true
      footerBottomConstraint?.isActive = false
      contentBottomConstraint?.isActive = true
    }

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

  public func configure(with viewModel: FKCellStatusDetailRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onBodyLinkTapped = nil
    onFooterActionTapped = nil
    iconSlot.reset()
    bodyView.resetForReuse()
    storedFooterAction = nil
    titleLabel.text = nil
    statusLabel.text = nil
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

    headerRow.axis = .horizontal
    headerRow.alignment = .top
    headerRow.spacing = FKCellLayoutMetrics.iconColumnSpacing

    titleStack.axis = .vertical
    titleStack.spacing = 4
    titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .boldSystemFont(ofSize: 17))
    titleLabel.numberOfLines = 0
    statusLabel.font = .preferredFont(forTextStyle: .subheadline)
    statusLabel.numberOfLines = 0

    footerStack.axis = .vertical
    footerStack.spacing = 12
    footerStack.translatesAutoresizingMaskIntoConstraints = false
    footerStack.isHidden = true
    footerButton.contentHorizontalAlignment = .leading
    footerButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
    footerButton.addTarget(self, action: #selector(handleFooterTap), for: .touchUpInside)
    footerStack.addArrangedSubview(footerSeparator)
    footerStack.addArrangedSubview(footerButton)

    bodyView.onLinkTapped = { [weak self] link in
      self?.onBodyLinkTapped?(link)
    }

    titleStack.addArrangedSubview(titleLabel)
    titleStack.addArrangedSubview(statusLabel)
    headerRow.addArrangedSubview(iconSlot)
    headerRow.addArrangedSubview(titleStack)
    rootStack.addArrangedSubview(headerRow)
    rootStack.addArrangedSubview(bodyView)

    bottomSeparator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(groupedBackground)
    contentView.addSubview(rootStack)
    contentView.addSubview(footerStack)
    contentView.addSubview(bottomSeparator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    contentBottomConstraint = rootStack.bottomAnchor.constraint(
      equalTo: contentView.bottomAnchor,
      constant: -insets.bottom
    )
    footerBottomConstraint = footerStack.bottomAnchor.constraint(
      equalTo: contentView.bottomAnchor,
      constant: -insets.bottom
    )
    contentBottomConstraint?.isActive = true

    NSLayoutConstraint.activate([
      groupedBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
      groupedBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      groupedBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      groupedBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),

      iconSlot.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.iconColumnWidth),

      footerStack.topAnchor.constraint(equalTo: rootStack.bottomAnchor, constant: 12),
      footerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      footerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.left),

      bottomSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      bottomSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      bottomSeparator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  @objc private func handleFooterTap() {
    guard let action = storedFooterAction else { return }
    onFooterActionTapped?(action)
  }
}
