import UIKit

@MainActor
final class FKCalloutMenuView: UIView {
  var onSelectItem: ((FKCalloutMenuItem) -> Void)?

  private static let rowHorizontalInset: CGFloat = 16
  private static let accessoryColumnWidth: CGFloat = 28
  private static let columnSpacing: CGFloat = 12

  private let stack = UIStackView()
  private var rowWidthConstraints: [NSLayoutConstraint] = []

  init(menu: FKCalloutMenu, configuration: FKCalloutConfiguration) {
    super.init(frame: .zero)
    setContentHuggingPriority(.defaultLow, for: .horizontal)
    setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 0
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor),
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    build(menu: menu, configuration: configuration)
    pinRowControlsToStackWidth()
  }

  private func pinRowControlsToStackWidth() {
    NSLayoutConstraint.deactivate(rowWidthConstraints)
    rowWidthConstraints.removeAll()
    for subview in stack.arrangedSubviews where subview is UIControl {
      rowWidthConstraints += [
        subview.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
        subview.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
      ]
    }
    NSLayoutConstraint.activate(rowWidthConstraints)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  static func preferredSize(
    menu: FKCalloutMenu,
    configuration: FKCalloutConfiguration,
    maxWidth: CGFloat,
    minWidth: CGFloat = 0
  ) -> CGSize {
    let bodyFont = Self.bodyFont(selected: false)
    let selectedBodyFont = Self.bodyFont(selected: true)
    let captionFont = UIFont.preferredFont(forTextStyle: .caption1)
    let headerFont = UIFont.preferredFont(forTextStyle: .caption2)
    let fixedRowChrome = rowHorizontalInset * 2 + accessoryColumnWidth * 2 + columnSpacing * 2
    var contentWidth: CGFloat = 0

    if let header = menu.header {
      contentWidth = max(
        contentWidth,
        ceil((header as NSString).size(withAttributes: [.font: headerFont]).width) + rowHorizontalInset * 2
      )
    }

    for section in menu.sections {
      for item in section.items {
        let titleFont = item.isSelected ? selectedBodyFont : bodyFont
        var textWidth = ceil((item.title as NSString).size(withAttributes: [.font: titleFont]).width)
        if let subtitle = item.subtitle {
          textWidth = max(
            textWidth,
            ceil((subtitle as NSString).size(withAttributes: [.font: captionFont]).width)
          )
        }
        contentWidth = max(contentWidth, fixedRowChrome + textWidth)
      }
    }

    var height: CGFloat = configuration.contentInsets.top + configuration.contentInsets.bottom
    if menu.header != nil {
      height += 38
    }
    for (sectionIndex, section) in menu.sections.enumerated() {
      if sectionIndex > 0 {
        height += 9
      }
      for item in section.items {
        height += item.subtitle == nil ? 48 : 60
      }
    }
    let width = max(minWidth, ceil(max(contentWidth, 1)))
    var totalHeight = height
    if let maxContentHeight = configuration.maxContentHeight, maxContentHeight > 0 {
      let contentOnly = height - configuration.contentInsets.top - configuration.contentInsets.bottom
      let capped = min(max(contentOnly, 0), maxContentHeight)
      totalHeight = capped + configuration.contentInsets.top + configuration.contentInsets.bottom
    }
    return CGSize(width: min(maxWidth, width), height: totalHeight)
  }

  private static func bodyFont(selected: Bool) -> UIFont {
    let font = UIFont.preferredFont(forTextStyle: .body)
    guard selected, let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) else {
      return font
    }
    return UIFont(descriptor: descriptor, size: 0)
  }

  private func build(menu: FKCalloutMenu, configuration: FKCalloutConfiguration) {
    if let header = menu.header {
      stack.addArrangedSubview(makeHeaderLabel(header, configuration: configuration))
      stack.addArrangedSubview(makeDivider(inset: 0))
    }

    for (sectionIndex, section) in menu.sections.enumerated() {
      if sectionIndex > 0 {
        stack.addArrangedSubview(makeDivider())
      }
      for item in section.items {
        stack.addArrangedSubview(makeRow(item: item, configuration: configuration))
      }
    }
  }

  private func makeHeaderLabel(_ text: String, configuration: FKCalloutConfiguration) -> UIView {
    let label = UILabel()
    label.font = UIFont.preferredFont(forTextStyle: .caption2)
    label.adjustsFontForContentSizeCategory = true
    label.textColor = configuration.appearance.resolvedSecondaryTextColor(traitCollection: traitCollection)
    label.text = text
    label.numberOfLines = 1
    let container = UIView()
    container.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 6, right: 16)
    label.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor),
      label.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor),
      label.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor),
    ])
    return container
  }

  private func makeDivider(inset: CGFloat = 14) -> UIView {
    let host = UIView()
    host.layoutMargins = UIEdgeInsets(top: 4, left: inset, bottom: 4, right: inset)
    let line = UIView()
    line.backgroundColor = UIColor.separator
    line.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(line)
    NSLayoutConstraint.activate([
      line.leadingAnchor.constraint(equalTo: host.layoutMarginsGuide.leadingAnchor),
      line.trailingAnchor.constraint(equalTo: host.layoutMarginsGuide.trailingAnchor),
      line.topAnchor.constraint(equalTo: host.layoutMarginsGuide.topAnchor),
      line.bottomAnchor.constraint(equalTo: host.layoutMarginsGuide.bottomAnchor),
      line.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
    ])
    return host
  }

  private func makeRow(item: FKCalloutMenuItem, configuration: FKCalloutConfiguration) -> UIView {
    let button = UIControl()
    button.isEnabled = item.isEnabled
    button.accessibilityLabel = item.subtitle.map { "\(item.title), \($0)" } ?? item.title
    if !item.isEnabled {
      button.accessibilityTraits.insert(.notEnabled)
    }
    if item.isEnabled {
      button.addAction(UIAction { [weak self] _ in
        self?.onSelectItem?(item)
      }, for: .touchUpInside)
    }

    let accentColor = item.tintColor ?? UIColor.systemBlue
    let restingBackground = item.isSelected ? accentColor.withAlphaComponent(0.08) : UIColor.clear
    button.backgroundColor = restingBackground
    if item.isEnabled {
      applyHighlightHandlers(to: button, restingBackground: restingBackground)
    }

    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = Self.columnSpacing
    row.isLayoutMarginsRelativeArrangement = true
    row.directionalLayoutMargins = NSDirectionalEdgeInsets(
      top: 12,
      leading: Self.rowHorizontalInset,
      bottom: 12,
      trailing: Self.rowHorizontalInset
    )
    row.isUserInteractionEnabled = false
    row.translatesAutoresizingMaskIntoConstraints = false

    let leadingSlot = makeAccessorySlot(width: Self.accessoryColumnWidth)
    if let image = resolvedIcon(for: item)?.withRenderingMode(.alwaysTemplate) {
      let iconView = UIImageView(image: image)
      iconView.tintColor = resolvedRowColor(for: item, configuration: configuration)
      iconView.contentMode = .scaleAspectFit
      iconView.translatesAutoresizingMaskIntoConstraints = false
      leadingSlot.addSubview(iconView)
      NSLayoutConstraint.activate([
        iconView.centerXAnchor.constraint(equalTo: leadingSlot.centerXAnchor),
        iconView.centerYAnchor.constraint(equalTo: leadingSlot.centerYAnchor),
        iconView.widthAnchor.constraint(equalToConstant: 20),
        iconView.heightAnchor.constraint(equalToConstant: 20),
      ])
    }
    row.addArrangedSubview(leadingSlot)

    let textStack = UIStackView()
    textStack.axis = .vertical
    textStack.spacing = 2
    textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textStack.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    let title = UILabel()
    title.font = Self.bodyFont(selected: item.isSelected)
    title.adjustsFontForContentSizeCategory = true
    title.textColor = resolvedRowColor(for: item, configuration: configuration)
    title.text = item.title
    title.numberOfLines = 1
    title.lineBreakMode = .byTruncatingTail
    title.setContentHuggingPriority(.defaultLow, for: .horizontal)
    title.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    textStack.addArrangedSubview(title)
    if let subtitle = item.subtitle {
      let subtitleLabel = UILabel()
      subtitleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
      subtitleLabel.adjustsFontForContentSizeCategory = true
      subtitleLabel.textColor = resolvedSubtitleColor(for: item, configuration: configuration)
      subtitleLabel.text = subtitle
      textStack.addArrangedSubview(subtitleLabel)
    }
    row.addArrangedSubview(textStack)

    let trailingSlot = makeAccessorySlot(width: Self.accessoryColumnWidth)
    if item.isSelected {
      let check = makeCheckmark(tintColor: item.isEnabled ? accentColor : .tertiaryLabel)
      trailingSlot.addSubview(check)
      check.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        check.centerXAnchor.constraint(equalTo: trailingSlot.centerXAnchor),
        check.centerYAnchor.constraint(equalTo: trailingSlot.centerYAnchor),
      ])
    }
    row.addArrangedSubview(trailingSlot)

    button.addSubview(row)
    button.setContentHuggingPriority(.defaultLow, for: .horizontal)
    button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
      row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
      row.topAnchor.constraint(equalTo: button.topAnchor),
      row.bottomAnchor.constraint(equalTo: button.bottomAnchor),
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: item.subtitle == nil ? 48 : 60),
    ])
    return button
  }

  private func resolvedRowColor(for item: FKCalloutMenuItem, configuration: FKCalloutConfiguration) -> UIColor {
    if !item.isEnabled {
      return .tertiaryLabel
    }
    if item.isDestructive {
      return .systemRed
    }
    return item.tintColor ?? configuration.appearance.resolvedTextColor(traitCollection: traitCollection)
  }

  private func resolvedSubtitleColor(for item: FKCalloutMenuItem, configuration: FKCalloutConfiguration) -> UIColor {
    if !item.isEnabled {
      return .quaternaryLabel
    }
    return configuration.appearance.resolvedSecondaryTextColor(traitCollection: traitCollection)
  }

  private func makeAccessorySlot(width: CGFloat) -> UIView {
    let slot = UIView()
    slot.translatesAutoresizingMaskIntoConstraints = false
    slot.widthAnchor.constraint(equalToConstant: width).isActive = true
    slot.setContentHuggingPriority(.required, for: .horizontal)
    slot.setContentCompressionResistancePriority(.required, for: .horizontal)
    return slot
  }

  private func makeCheckmark(tintColor: UIColor) -> UIImageView {
    let check = UIImageView(
      image: UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
    )
    check.tintColor = tintColor
    check.setContentHuggingPriority(.required, for: .horizontal)
    return check
  }

  private func applyHighlightHandlers(to control: UIControl, restingBackground: UIColor) {
    let highlight = UIColor.label.withAlphaComponent(0.06)
    control.addAction(UIAction { _ in control.backgroundColor = highlight }, for: .touchDown)
    control.addAction(UIAction { _ in control.backgroundColor = restingBackground }, for: .touchUpInside)
    control.addAction(UIAction { _ in control.backgroundColor = restingBackground }, for: .touchUpOutside)
    control.addAction(UIAction { _ in control.backgroundColor = restingBackground }, for: .touchCancel)
    control.addAction(UIAction { _ in control.backgroundColor = restingBackground }, for: .touchDragExit)
  }

  private func resolvedIcon(for item: FKCalloutMenuItem) -> UIImage? {
    if let icon = item.icon {
      return icon
    }
    if let symbolName = item.symbolName {
      return UIImage(systemName: symbolName)
    }
    return nil
  }
}
