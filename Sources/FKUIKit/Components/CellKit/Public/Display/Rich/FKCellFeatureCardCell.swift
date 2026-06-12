import FKCoreKit
import UIKit

/// Hero icon, title, description, separator, and CTA in a single card row (D-12).
@MainActor
public final class FKCellFeatureCardCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellFeatureCardRow

  /// Called when the user taps the footer CTA.
  public var onPrimaryActionTapped: ((FKCellActionLink) -> Void)?

  private let chrome = FKCellRichCardChromeView()
  private let iconSlot = FKCellIconSlotView()
  private let titleLabel = UILabel()
  private let descriptionLabel = UILabel()
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

  public func apply(_ configuration: FKCellFeatureCardConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellFeatureCardConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    self.appearance = appearance
    storedAction = configuration.primaryAction

    if let icon = configuration.icon {
      iconSlot.apply(icon)
      iconSlot.isHidden = false
    } else {
      iconSlot.isHidden = true
    }

    titleLabel.text = configuration.title
    descriptionLabel.text = configuration.description

    let linkColor = appearance.linkColor.resolvedColor(with: traitCollection)
    chrome.footerButton.setTitleColor(linkColor, for: .normal)
    chrome.setFooterAction(configuration.primaryAction, showsSeparator: true)
    chrome.applyAppearance(appearance)
    chrome.applyChrome(
      separatorPolicy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection,
      to: self
    )

    selectionStyle = .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellFeatureCardRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onPrimaryActionTapped = nil
    storedAction = nil
    iconSlot.reset()
    titleLabel.text = nil
    descriptionLabel.text = nil
    chrome.resetForReuse()
    rebuildContent()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .boldSystemFont(ofSize: 22))
    titleLabel.numberOfLines = 0
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.textAlignment = .center

    descriptionLabel.font = .preferredFont(forTextStyle: .body)
    descriptionLabel.textColor = .secondaryLabel
    descriptionLabel.numberOfLines = 0
    descriptionLabel.adjustsFontForContentSizeCategory = true
    descriptionLabel.textAlignment = .center

    bottomSeparator.translatesAutoresizingMaskIntoConstraints = false
    chrome.footerButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)

    contentView.addSubview(chrome)
    contentView.addSubview(bottomSeparator)
    NSLayoutConstraint.activate([
      chrome.topAnchor.constraint(equalTo: contentView.topAnchor),
      chrome.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      chrome.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      chrome.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      bottomSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      bottomSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      bottomSeparator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    rebuildContent()
  }

  private func rebuildContent() {
    chrome.resetForReuse()
    chrome.contentStack.alignment = .center
    chrome.contentStack.addArrangedSubview(iconSlot)
    chrome.contentStack.addArrangedSubview(titleLabel)
    chrome.contentStack.addArrangedSubview(descriptionLabel)
    NSLayoutConstraint.activate([
      iconSlot.widthAnchor.constraint(equalToConstant: 64),
      iconSlot.heightAnchor.constraint(equalToConstant: 64),
    ])
  }

  @objc private func handleActionTap() {
    guard let action = storedAction else { return }
    onPrimaryActionTapped?(action)
  }
}
