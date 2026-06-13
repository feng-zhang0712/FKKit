import FKCoreKit
import UIKit

/// Collection preset cell sharing layout with ``FKListPresetTableCell``.
@MainActor
public final class FKListPresetCollectionCell: UICollectionViewCell, FKListCollectionCellConfigurable {
  public typealias Item = FKListPresetCellContext

  private static let leadingDimension: CGFloat = 28

  private let cardView = UIView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let valueLabel = UILabel()
  private let leadingImageView = UIImageView()
  private let remoteImageView = FKImageView(profile: .listCell)
  private let trailingSwitch = UISwitch()
  private let trailingCheckbox = UIImageView()
  private let trailingAccessory = UIImageView()
  private let textStack = UIStackView()
  private let mainStack = UIStackView()
  private var cardConstraints: [NSLayoutConstraint] = []
  private var context: FKListPresetCellContext?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    remoteImageView.resetForReuse()
    leadingImageView.image = nil
    context = nil
    applyCardChrome(isEnabled: false)
  }

  public func configure(with item: FKListPresetCellContext) {
    context = item
    applyCardChrome(isEnabled: item.displaysCardChrome)
    resetStack()
    applyAppearance(item.appearance)
    applyPreset(item)
    applyEnabledState(item)
    updateAccessibility(item)
  }

  private func setup() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    cardView.backgroundColor = .secondarySystemGroupedBackground
    cardView.layer.cornerRadius = 12
    cardView.layer.masksToBounds = true
    cardView.translatesAutoresizingMaskIntoConstraints = false
    cardView.isHidden = true
    contentView.addSubview(cardView)

    titleLabel.numberOfLines = 0
    subtitleLabel.numberOfLines = 0
    valueLabel.numberOfLines = 1
    valueLabel.textAlignment = .right
    valueLabel.setContentHuggingPriority(.required, for: .horizontal)
    valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

    leadingImageView.contentMode = .scaleAspectFit
    leadingImageView.setContentHuggingPriority(.required, for: .horizontal)
    leadingImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    leadingImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      leadingImageView.widthAnchor.constraint(equalToConstant: Self.leadingDimension),
      leadingImageView.heightAnchor.constraint(equalToConstant: Self.leadingDimension),
    ])

    remoteImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      remoteImageView.widthAnchor.constraint(equalToConstant: Self.leadingDimension),
      remoteImageView.heightAnchor.constraint(equalToConstant: Self.leadingDimension),
    ])

    trailingCheckbox.contentMode = .scaleAspectFit
    trailingCheckbox.tintColor = .systemBlue
    NSLayoutConstraint.activate([
      trailingCheckbox.widthAnchor.constraint(equalToConstant: 22),
      trailingCheckbox.heightAnchor.constraint(equalToConstant: 22),
    ])

    trailingAccessory.contentMode = .scaleAspectFit
    trailingAccessory.tintColor = .tertiaryLabel
    NSLayoutConstraint.activate([
      trailingAccessory.widthAnchor.constraint(equalToConstant: 12),
      trailingAccessory.heightAnchor.constraint(equalToConstant: 20),
    ])

    trailingSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)

    textStack.axis = .vertical
    textStack.spacing = 2
    textStack.alignment = .leading
    textStack.addArrangedSubview(titleLabel)
    textStack.addArrangedSubview(subtitleLabel)

    mainStack.axis = .horizontal
    mainStack.spacing = 12
    mainStack.alignment = .center
    mainStack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(mainStack)

    NSLayoutConstraint.activate([
      mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
      mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11),
      contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }

  private func resetStack() {
    for view in mainStack.arrangedSubviews {
      mainStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    subtitleLabel.isHidden = true
    leadingImageView.isHidden = true
    remoteImageView.isHidden = true
    valueLabel.isHidden = true
    trailingSwitch.isHidden = true
    trailingCheckbox.isHidden = true
    trailingAccessory.isHidden = true
  }

  private func applyAppearance(_ appearance: FKListAppearanceConfiguration) {
    titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: appearance.titleFont)
    subtitleLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: appearance.subtitleFont)
    titleLabel.textColor = appearance.titleColor
    subtitleLabel.textColor = appearance.subtitleColor
    valueLabel.font = titleLabel.font
    valueLabel.textColor = appearance.subtitleColor
  }

  private func applyPreset(_ item: FKListPresetCellContext) {
    switch item.preset {
    case .text(let row):
      titleLabel.text = row.title
      mainStack.addArrangedSubview(textStack)

    case .subtitle(let row):
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
      mainStack.addArrangedSubview(textStack)

    case .icon(let row):
      configureLeading(row.leading)
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
      mainStack.addArrangedSubview(leadingView)
      mainStack.addArrangedSubview(textStack)

    case .switch(let row):
      configureLeading(row.leading)
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
      trailingSwitch.isOn = row.isOn
      trailingSwitch.isEnabled = row.isEnabled
      trailingSwitch.isHidden = false
      if row.leading != nil { mainStack.addArrangedSubview(leadingView) }
      mainStack.addArrangedSubview(textStack)
      mainStack.addArrangedSubview(UIView())
      mainStack.addArrangedSubview(trailingSwitch)

    case .checkbox(let row):
      configureLeading(row.leading)
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
      trailingCheckbox.image = UIImage(systemName: row.isChecked ? "checkmark.circle.fill" : "circle")
      trailingCheckbox.isHidden = false
      if row.leading != nil { mainStack.addArrangedSubview(leadingView) }
      mainStack.addArrangedSubview(textStack)
      mainStack.addArrangedSubview(UIView())
      mainStack.addArrangedSubview(trailingCheckbox)

    case .disclosure(let row):
      configureLeading(row.leading)
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
      applyAccessory(row.accessory)
      if row.leading != nil { mainStack.addArrangedSubview(leadingView) }
      mainStack.addArrangedSubview(textStack)
      if !trailingAccessory.isHidden {
        mainStack.addArrangedSubview(trailingAccessory)
      }

    case .customValue(let row):
      configureLeading(row.leading)
      titleLabel.text = row.title
      subtitleLabel.text = row.subtitle
      subtitleLabel.isHidden = row.subtitle?.isEmpty != false
      valueLabel.text = row.value
      valueLabel.isHidden = false
      if row.leading != nil { mainStack.addArrangedSubview(leadingView) }
      mainStack.addArrangedSubview(textStack)
      mainStack.addArrangedSubview(UIView())
      mainStack.addArrangedSubview(valueLabel)
    }
  }

  private var leadingView: UIView {
    remoteImageView.isHidden ? leadingImageView : remoteImageView
  }

  private func configureLeading(_ leading: FKListLeadingContent?) {
    guard let leading else {
      leadingImageView.isHidden = true
      remoteImageView.resetForReuse()
      remoteImageView.isHidden = true
      return
    }
    switch leading {
    case .asset(let name):
      remoteImageView.resetForReuse()
      remoteImageView.isHidden = true
      leadingImageView.image = UIImage(named: name)
      leadingImageView.isHidden = leadingImageView.image == nil
    case .symbol(let name):
      remoteImageView.resetForReuse()
      remoteImageView.isHidden = true
      leadingImageView.image = UIImage(systemName: name)
      leadingImageView.isHidden = false
    case .remoteURL(let url):
      leadingImageView.isHidden = true
      remoteImageView.isHidden = false
      remoteImageView.url = url
    }
  }

  private func applyAccessory(_ accessory: FKListAccessory) {
    switch accessory {
    case .none, .customView:
      trailingAccessory.isHidden = true
    case .disclosureIndicator:
      trailingAccessory.image = UIImage(systemName: "chevron.right")
      trailingAccessory.isHidden = false
    case .checkmark:
      trailingAccessory.image = UIImage(systemName: "checkmark")
      trailingAccessory.isHidden = false
    }
  }

  private func applyEnabledState(_ item: FKListPresetCellContext) {
    let metadata = item.metadata
    let enabled: Bool
    let selectable: Bool

    switch item.preset {
    case .text(let row):
      enabled = row.isEnabled; selectable = row.isSelectable
    case .subtitle(let row):
      enabled = row.isEnabled; selectable = row.isSelectable
    case .icon(let row):
      enabled = row.isEnabled; selectable = row.isSelectable
    case .switch(let row):
      enabled = row.isEnabled; selectable = false
    case .checkbox(let row):
      enabled = row.isEnabled; selectable = false
    case .disclosure(let row):
      enabled = row.isEnabled; selectable = row.isSelectable
    case .customValue(let row):
      enabled = row.isEnabled; selectable = row.isSelectable
    }

    let resolvedEnabled = metadata?.isEnabled ?? enabled
    contentView.alpha = resolvedEnabled ? 1 : item.appearance.disabledAlpha
    isUserInteractionEnabled = resolvedEnabled
    trailingSwitch.isEnabled = resolvedEnabled
  }

  private func updateAccessibility(_ item: FKListPresetCellContext) {
    var parts: [String] = []
    if let title = titleLabel.text, !title.isEmpty { parts.append(title) }
    if let subtitle = subtitleLabel.text, !subtitle.isEmpty { parts.append(subtitle) }
    accessibilityLabel = parts.joined(separator: ", ")

    switch item.preset {
    case .switch:
      accessibilityTraits = [.button]
      accessibilityValue = trailingSwitch.isOn ? "On" : "Off"
    case .checkbox(let row):
      accessibilityTraits = [.button]
      accessibilityValue = row.isChecked ? "Checked" : "Unchecked"
    default:
      accessibilityTraits = .staticText
    }
  }

  @objc private func switchChanged() {
    guard let context else { return }
    if case .switch(let row) = context.preset {
      context.switchHandlerRegistry.handler(for: row.handlerID)?(context.itemID, trailingSwitch.isOn)
    }
  }

  private func applyCardChrome(isEnabled: Bool) {
    NSLayoutConstraint.deactivate(cardConstraints)
    cardConstraints.removeAll()
    cardView.isHidden = !isEnabled
    backgroundColor = isEnabled ? .clear : .systemBackground
    if isEnabled {
      cardConstraints = [
        cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
        cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ]
      NSLayoutConstraint.activate(cardConstraints)
    }
  }
}
