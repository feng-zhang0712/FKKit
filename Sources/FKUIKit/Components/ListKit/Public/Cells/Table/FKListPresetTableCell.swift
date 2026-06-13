import FKCoreKit
import UIKit

/// Binding model passed to ``FKListPresetTableCell``.
public struct FKListPresetCellContext: @unchecked Sendable {
  public var itemID: FKListItemID
  public var preset: FKListPresetItem
  public var metadata: FKListItemMetadata?
  public var appearance: FKListAppearanceConfiguration
  public var separatorMode: FKListSeparatorMode
  public var switchHandlerRegistry: FKListSwitchHandlerRegistry
  public var checkboxHandlerRegistry: FKListCheckboxHandlerRegistry
  /// When `true`, collection cells render grouped card chrome (grid preset).
  public var displaysCardChrome: Bool

  public init(
    itemID: FKListItemID,
    preset: FKListPresetItem,
    metadata: FKListItemMetadata?,
    appearance: FKListAppearanceConfiguration,
    separatorMode: FKListSeparatorMode,
    switchHandlerRegistry: FKListSwitchHandlerRegistry,
    checkboxHandlerRegistry: FKListCheckboxHandlerRegistry,
    displaysCardChrome: Bool = false
  ) {
    self.itemID = itemID
    self.preset = preset
    self.metadata = metadata
    self.appearance = appearance
    self.separatorMode = separatorMode
    self.switchHandlerRegistry = switchHandlerRegistry
    self.checkboxHandlerRegistry = checkboxHandlerRegistry
    self.displaysCardChrome = displaysCardChrome
  }
}

/// Unified preset table cell for all ``FKListPresetItem`` cases.
@MainActor
public final class FKListPresetTableCell: UITableViewCell, FKListTableCellConfigurable {
  public typealias Item = FKListPresetCellContext

  public static let reuseIdentifier = "FKListPresetTableCell"

  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let valueLabel = UILabel()
  private let leadingImageView = UIImageView()
  private let remoteImageView = FKImageView(profile: .listCell)
  private let trailingSwitch = UISwitch()
  private let trailingCheckbox = UIImageView()
  private let textStack = UIStackView()
  private let mainStack = UIStackView()
  private var divider: FKDivider?
  private var context: FKListPresetCellContext?

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  public func configure(with item: FKListPresetCellContext) {
    context = item
    resetTrailingViews()
    applyAppearance(item.appearance)
    applySeparator(item.separatorMode, appearance: item.appearance)
    applyPreset(item)
    applyEnabledState(item)
    updateAccessibility(item)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    remoteImageView.resetForReuse()
    leadingImageView.image = nil
    accessoryType = .none
    accessoryView = nil
    divider?.removeFromSuperview()
    divider = nil
    context = nil
  }

  private func setup() {
    selectionStyle = .default
    backgroundColor = .systemBackground

    titleLabel.numberOfLines = 0
    subtitleLabel.numberOfLines = 0
    valueLabel.numberOfLines = 1
    valueLabel.textAlignment = .right
    valueLabel.setContentHuggingPriority(.required, for: .horizontal)
    valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

    leadingImageView.contentMode = .scaleAspectFit
    leadingImageView.setContentHuggingPriority(.required, for: .horizontal)
    leadingImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    NSLayoutConstraint.activate([
      leadingImageView.widthAnchor.constraint(equalToConstant: 28),
      leadingImageView.heightAnchor.constraint(equalToConstant: 28),
    ])

    remoteImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      remoteImageView.widthAnchor.constraint(equalToConstant: 28),
      remoteImageView.heightAnchor.constraint(equalToConstant: 28),
    ])

    trailingCheckbox.contentMode = .scaleAspectFit
    trailingCheckbox.tintColor = .systemBlue
    NSLayoutConstraint.activate([
      trailingCheckbox.widthAnchor.constraint(equalToConstant: 22),
      trailingCheckbox.heightAnchor.constraint(equalToConstant: 22),
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
    mainStack.isLayoutMarginsRelativeArrangement = true
    mainStack.layoutMargins = UIEdgeInsets(top: 11, left: 16, bottom: 11, right: 16)
    contentView.addSubview(mainStack)

    NSLayoutConstraint.activate([
      mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
      mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }

  private func resetTrailingViews() {
    for view in mainStack.arrangedSubviews { mainStack.removeArrangedSubview(view); view.removeFromSuperview() }
    subtitleLabel.isHidden = true
    leadingImageView.isHidden = true
    remoteImageView.isHidden = true
    valueLabel.isHidden = true
    trailingSwitch.isHidden = true
    trailingCheckbox.isHidden = true
  }

  private func applyAppearance(_ appearance: FKListAppearanceConfiguration) {
    titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: appearance.titleFont)
    subtitleLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: appearance.subtitleFont)
    titleLabel.textColor = appearance.titleColor
    subtitleLabel.textColor = appearance.subtitleColor
    valueLabel.font = titleLabel.font
    valueLabel.textColor = appearance.subtitleColor
    let selected = UIView()
    selected.backgroundColor = appearance.selectedBackgroundColor
    selectedBackgroundView = selected
  }

  private func applySeparator(_ mode: FKListSeparatorMode, appearance: FKListAppearanceConfiguration) {
    separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    switch mode {
    case .system:
      separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
    case .fkDivider(let inset):
      var dividerConfig = FKDivider.defaultConfiguration
      dividerConfig.color = appearance.separatorColor
      divider = contentView.fk_addDivider(at: .bottom, configuration: dividerConfig, margin: inset)
    case .none:
      break
    }
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
    case .none:
      accessoryType = .none
    case .disclosureIndicator:
      accessoryType = .disclosureIndicator
    case .checkmark:
      accessoryType = .checkmark
    case .customView:
      accessoryType = .none
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
    let resolvedSelectable = metadata?.isSelectable ?? selectable
    isUserInteractionEnabled = resolvedEnabled
    alpha = resolvedEnabled ? 1 : item.appearance.disabledAlpha
    selectionStyle = resolvedSelectable ? .default : .none
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
}
