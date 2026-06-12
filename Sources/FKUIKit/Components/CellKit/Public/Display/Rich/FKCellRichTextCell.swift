import FKCoreKit
import UIKit

/// Rich text card with optional footer link (D-07) or compact announcement layout (D-22).
@MainActor
public final class FKCellRichTextCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellRichTextRow

  /// Called when the user taps an inline body link range.
  public var onBodyLinkTapped: ((FKCellLinkRange) -> Void)?
  /// Called when the user taps the footer action link.
  public var onFooterActionTapped: ((FKCellActionLink) -> Void)?

  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  private let rootStack = UIStackView()
  private let headerRow = UIStackView()
  private let iconSlot = FKCellIconSlotView()
  private let titleLabel = UILabel()
  private let timestampLabel = UILabel()
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

  public func apply(_ configuration: FKCellRichTextConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellRichTextConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    self.appearance = appearance
    storedFooterAction = configuration.footerAction

    switch configuration.style {
    case .standard:
      iconSlot.isHidden = true
      headerRow.isHidden = false
      titleLabel.text = configuration.title
      titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .boldSystemFont(ofSize: 17))
      timestampLabel.isHidden = true
    case .compact:
      if let icon = configuration.leadingIcon {
        iconSlot.apply(icon)
        iconSlot.isHidden = false
      } else {
        iconSlot.isHidden = true
      }
      titleLabel.text = configuration.title
      titleLabel.font = .preferredFont(forTextStyle: .body)
      if let timestamp = configuration.timestamp {
        timestampLabel.text = timestamp
        timestampLabel.isHidden = false
      } else {
        timestampLabel.isHidden = true
      }
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

    groupedBackgroundHost.apply(nil, in: contentView)
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

  public func configure(with viewModel: FKCellRichTextRow) {
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
    timestampLabel.text = nil
    footerButton.setTitle(nil, for: .normal)
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    headerRow.axis = .horizontal
    headerRow.alignment = .center
    headerRow.spacing = FKCellLayoutMetrics.iconColumnSpacing

    titleLabel.numberOfLines = 0
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

    timestampLabel.font = .preferredFont(forTextStyle: .footnote)
    timestampLabel.textColor = .tertiaryLabel
    timestampLabel.setContentHuggingPriority(.required, for: .horizontal)

    footerStack.axis = .vertical
    footerStack.spacing = 12
    footerStack.translatesAutoresizingMaskIntoConstraints = false
    footerStack.isHidden = true

    footerButton.contentHorizontalAlignment = .leading
    footerButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
    footerButton.addTarget(self, action: #selector(handleFooterTap), for: .touchUpInside)

    footerStack.addArrangedSubview(footerSeparator)
    footerStack.addArrangedSubview(footerButton)

    bottomSeparator.translatesAutoresizingMaskIntoConstraints = false

    bodyView.onLinkTapped = { [weak self] link in
      self?.onBodyLinkTapped?(link)
    }

    headerRow.addArrangedSubview(iconSlot)
    headerRow.addArrangedSubview(titleLabel)
    headerRow.addArrangedSubview(timestampLabel)
    rootStack.addArrangedSubview(headerRow)
    rootStack.addArrangedSubview(bodyView)
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
