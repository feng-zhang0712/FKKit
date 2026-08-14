import UIKit

/// Mutually exclusive radio option group with optional card chrome, header, and footer.
@MainActor
public final class FKRadioGroup: UIControl {
  public var configuration: FKRadioGroupConfiguration {
    didSet {
      guard oldValue != configuration else { return }
      rebuild()
    }
  }

  public var options: [FKRadioOption] = [] {
    didSet {
      guard oldValue != options else { return }
      reconcileSelectionAfterOptionsChange()
      rebuild()
    }
  }

  public var headerTitle: String? {
    didSet { updateHeaderFooter(); invalidateIntrinsicContentSize(); setNeedsLayout() }
  }

  public var footerTitle: String? {
    didSet { updateHeaderFooter(); invalidateIntrinsicContentSize(); setNeedsLayout() }
  }

  public var selectedOptionID: FKRadioOptionID? {
    get { _selectedOptionID }
    set { setSelectedOptionID(newValue, animated: false, sendActions: false) }
  }

  public var selectedOption: FKRadioOption? {
    guard let id = _selectedOptionID else { return nil }
    return options.first { $0.id == id }
  }

  public var showsError: Bool = false {
    didSet {
      guard oldValue != showsError else { return }
      applyCardChrome()
      updateAccessibility()
    }
  }

  public var onSelectionChanged: ((FKRadioOptionID?) -> Void)?

  private var _selectedOptionID: FKRadioOptionID?
  private let headerLabel = UILabel()
  private let footerLabel = UILabel()
  private let cardView = UIView()
  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private var rowButtons: [FKRadioButton] = []
  private var separators: [FKDivider] = []

  public override init(frame: CGRect) {
    configuration = FKSelectionControlDefaults.radioGroup
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    configuration = FKSelectionControlDefaults.radioGroup
    super.init(coder: coder)
    commonInit()
  }

  public init(
    configuration: FKRadioGroupConfiguration = FKSelectionControlDefaults.radioGroup,
    options: [FKRadioOption] = []
  ) {
    self.configuration = configuration
    super.init(frame: .zero)
    // Assign before `commonInit()` so the first `rebuild()` sees options.
    // Property `didSet` does not run while initializing this type.
    self.options = options
    commonInit()
  }

  private func commonInit() {
    isAccessibilityElement = false
    accessibilityContainerType = .semanticGroup
    backgroundColor = .clear
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .vertical)

    headerLabel.numberOfLines = 0
    footerLabel.numberOfLines = 0
    headerLabel.isAccessibilityElement = false
    footerLabel.isAccessibilityElement = false

    scrollView.alwaysBounceVertical = false
    scrollView.showsVerticalScrollIndicator = true
    scrollView.addSubview(contentView)
    cardView.addSubview(scrollView)

    addSubview(headerLabel)
    addSubview(cardView)
    addSubview(footerLabel)

    applyCardChrome()
    updateHeaderFooter()
    rebuild()
  }

  public func apply(_ configuration: FKRadioGroupConfiguration) {
    self.configuration = configuration
  }

  public func setSelectedOptionID(_ id: FKRadioOptionID?, animated: Bool, sendActions: Bool) {
    if let id, !options.contains(where: { $0.id == id }) {
      #if DEBUG
      print("[FKRadioGroup] Ignoring unknown option id: \(id)")
      #endif
      return
    }
    if id == nil, !configuration.interaction.allowsEmptySelection, !options.isEmpty {
      return
    }
    applySelection(id, animated: animated, sendActions: sendActions)
  }

  public func selectOption(id: FKRadioOptionID, animated: Bool = true, sendActions: Bool = true) {
    setSelectedOptionID(id, animated: animated, sendActions: sendActions)
  }

  public func option(id: FKRadioOptionID) -> FKRadioOption? {
    options.first { $0.id == id }
  }

  public override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: measuredHeight(forWidth: layoutWidth()))
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    let width = size.width > 0 ? size.width : layoutWidth()
    return CGSize(width: width, height: measuredHeight(forWidth: width))
  }

  public override func systemLayoutSizeFitting(
    _ targetSize: CGSize,
    withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
    verticalFittingPriority: UILayoutPriority
  ) -> CGSize {
    let width = targetSize.width > 0 ? targetSize.width : layoutWidth()
    return CGSize(width: width, height: measuredHeight(forWidth: width))
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let width = bounds.width
    guard width > 0 else { return }

    var y: CGFloat = 0
    if !headerLabel.isHidden {
      let headerSize = headerLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
      headerLabel.frame = CGRect(x: 0, y: y, width: width, height: headerSize.height)
      y = headerLabel.frame.maxY + configuration.layout.headerFooterSpacing
    } else {
      headerLabel.frame = .zero
    }

    let footerHeight: CGFloat = footerLabel.isHidden
      ? 0
      : footerLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    let footerBlock = footerHeight > 0 ? footerHeight + configuration.layout.headerFooterSpacing : 0
    let cardMaxHeight = max(0, bounds.height - y - footerBlock)
    let contentHeight = stackContentHeight(forWidth: width)

    let cardHeight: CGFloat
    if let maxVisible = configuration.layout.maximumVisibleOptions, configuration.layout.style != .horizontal {
      let capped = rowHeightEstimate() * CGFloat(maxVisible)
      cardHeight = min(contentHeight, capped)
      scrollView.isScrollEnabled = contentHeight > capped + 0.5
    } else if bounds.height > 0, cardMaxHeight > 0, contentHeight > cardMaxHeight + 0.5 {
      cardHeight = cardMaxHeight
      scrollView.isScrollEnabled = configuration.layout.style != .horizontal
    } else {
      cardHeight = max(contentHeight, 0)
      scrollView.isScrollEnabled = false
    }

    cardView.frame = CGRect(x: 0, y: y, width: width, height: cardHeight)
    scrollView.frame = cardView.bounds

    if configuration.layout.style == .horizontal {
      layoutHorizontalRows(in: width, height: max(cardHeight, rowHeightEstimate()))
    } else {
      layoutVerticalRows(in: width, contentHeight: contentHeight)
    }

    if !footerLabel.isHidden {
      let footerY = cardView.frame.maxY + configuration.layout.headerFooterSpacing
      footerLabel.frame = CGRect(x: 0, y: footerY, width: width, height: footerHeight)
    } else {
      footerLabel.frame = .zero
    }
  }

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    applyCardChrome()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  // MARK: - Private

  private func rebuild() {
    validateDuplicateIDs()
    rowButtons.forEach { $0.removeFromSuperview() }
    separators.forEach { $0.removeFromSuperview() }
    rowButtons.removeAll()
    separators.removeAll()

    let uniqueOptions = deduplicatedOptions()
    for (index, option) in uniqueOptions.enumerated() {
      let button = makeRowButton(for: option)
      rowButtons.append(button)
      contentView.addSubview(button)

      if configuration.layout.style != .horizontal, index < uniqueOptions.count - 1 {
        let divider = makeSeparator()
        separators.append(divider)
        contentView.addSubview(divider)
      }
    }

    applyCardChrome()
    syncRowSelection(animated: false)
    updateAccessibility()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  private func makeRowButton(for option: FKRadioOption) -> FKRadioButton {
    var buttonConfig = FKRadioButtonConfiguration()
    buttonConfig.layout.size = configuration.layout.size
    buttonConfig.layout.indicatorEdge = configuration.layout.indicatorEdge
    buttonConfig.layout.contentInsets = configuration.layout.rowContentInsets
    buttonConfig.layout.rowMinHeight = configuration.layout.rowMinHeight
    buttonConfig.layout.indicatorTitleSpacing = configuration.layout.indicatorTitleSpacing
    buttonConfig.layout.titleSubtitleSpacing = configuration.layout.titleSubtitleSpacing
    buttonConfig.layout.imageTitleSpacing = configuration.layout.imageTitleSpacing
    buttonConfig.appearance.tint = configuration.appearance.tint
    buttonConfig.appearance.titleColor = configuration.appearance.titleColor
    buttonConfig.appearance.subtitleColor = configuration.appearance.subtitleColor
    buttonConfig.appearance.disabledTitleColor = configuration.appearance.disabledTitleColor
    buttonConfig.appearance.titleFont = configuration.appearance.titleFont
    buttonConfig.appearance.subtitleFont = configuration.appearance.subtitleFont
    buttonConfig.appearance.disabledAlpha = configuration.appearance.disabledAlpha
    buttonConfig.appearance.pressedAlpha = configuration.appearance.pressedAlpha
    buttonConfig.appearance.uncheckedBorderColor = configuration.appearance.uncheckedBorderColor
    buttonConfig.motion = configuration.motion

    let content = FKRadioButtonContentConfiguration(
      title: option.title,
      subtitle: option.subtitle,
      image: option.image
    )
    let button = FKRadioButton(configuration: buttonConfig, content: content)
    button.selectionManagedExternally = true
    button.isEnabled = option.isEnabled && isEnabled
    if let label = option.accessibilityLabel {
      button.configuration.accessibility.customLabel = label
    }
    button.addTarget(self, action: #selector(rowTapped(_:)), for: .primaryActionTriggered)
    button.setContentHuggingPriority(.defaultLow, for: .horizontal)
    button.setContentCompressionResistancePriority(.required, for: .vertical)
    return button
  }

  private func makeSeparator() -> FKDivider {
    let insets = configuration.layout.separatorInset
    let edge = UIEdgeInsets(
      top: insets.top,
      left: insets.leading,
      bottom: insets.bottom,
      right: insets.trailing
    )
    return FKDivider(configuration: FKDividerConfiguration(
      direction: .horizontal,
      color: configuration.appearance.separatorColor,
      contentInsets: edge,
      isPixelPerfect: true
    ))
  }

  @objc private func rowTapped(_ sender: FKRadioButton) {
    guard isEnabled else { return }
    guard let index = rowButtons.firstIndex(of: sender) else { return }
    let unique = deduplicatedOptions()
    guard index < unique.count else { return }
    let option = unique[index]
    guard option.isEnabled else { return }

    if option.id == _selectedOptionID {
      if configuration.interaction.allowsDeselection, configuration.interaction.allowsEmptySelection {
        applySelection(nil, animated: true, sendActions: true)
      }
      return
    }
    applySelection(option.id, animated: true, sendActions: true)
  }

  private func applySelection(_ id: FKRadioOptionID?, animated: Bool, sendActions: Bool) {
    let changed = id != _selectedOptionID
    _selectedOptionID = id
    syncRowSelection(animated: animated)
    updateAccessibility()
    guard changed, sendActions else { return }
    FKSelectionControlHaptics.fire(configuration.interaction.haptic)
    self.sendActions(for: .valueChanged)
    onSelectionChanged?(id)
  }

  private func syncRowSelection(animated: Bool) {
    let unique = deduplicatedOptions()
    for (index, button) in rowButtons.enumerated() {
      let selected = index < unique.count && unique[index].id == _selectedOptionID
      button.setSelected(selected, animated: animated, sendActions: false)
    }
  }

  private func reconcileSelectionAfterOptionsChange() {
    validateDuplicateIDs()
    let unique = deduplicatedOptions()
    if let current = _selectedOptionID {
      if let option = unique.first(where: { $0.id == current }) {
        if !option.isEnabled, configuration.interaction.reselectWhenSelectedOptionDisabled {
          _selectedOptionID = unique.first(where: \.isEnabled)?.id
        }
        return
      }
      if configuration.interaction.allowsEmptySelection || unique.isEmpty {
        _selectedOptionID = nil
      } else {
        _selectedOptionID = unique.first(where: \.isEnabled)?.id ?? unique.first?.id
      }
      return
    }
    if unique.isEmpty {
      _selectedOptionID = nil
    }
  }

  private func deduplicatedOptions() -> [FKRadioOption] {
    var seen = Set<FKRadioOptionID>()
    var result: [FKRadioOption] = []
    for option in options {
      if seen.contains(option.id) { continue }
      seen.insert(option.id)
      result.append(option)
    }
    return result
  }

  private func validateDuplicateIDs() {
    var seen = Set<FKRadioOptionID>()
    var hasDuplicate = false
    for option in options {
      if seen.contains(option.id) {
        hasDuplicate = true
        break
      }
      seen.insert(option.id)
    }
    guard hasDuplicate else { return }
    switch configuration.interaction.duplicateIDPolicy {
    case .assertInDebug:
      assertionFailure("FKRadioGroup options contain duplicate ids; keeping the first occurrence.")
    case .keepFirst:
      break
    }
  }

  private func updateHeaderFooter() {
    headerLabel.text = headerTitle
    headerLabel.font = configuration.appearance.headerFont
    headerLabel.textColor = configuration.appearance.headerColor
    headerLabel.isHidden = (headerTitle ?? "").isEmpty

    footerLabel.text = footerTitle
    footerLabel.font = configuration.appearance.footerFont
    footerLabel.textColor = configuration.appearance.footerColor
    footerLabel.isHidden = (footerTitle ?? "").isEmpty
  }

  private func applyCardChrome() {
    let grouped = configuration.layout.style == .insetGrouped
    cardView.backgroundColor = grouped ? configuration.appearance.cardBackgroundColor : .clear
    cardView.layer.cornerRadius = grouped ? configuration.layout.cornerRadius : 0
    cardView.layer.cornerCurve = .continuous
    cardView.layer.borderWidth = grouped ? configuration.appearance.cardBorderWidth : 0
    let borderColor = showsError
      ? configuration.appearance.errorBorderColor
      : configuration.appearance.cardBorderColor
    cardView.layer.borderColor = borderColor.resolvedColor(with: traitCollection).cgColor
    cardView.clipsToBounds = grouped
    updateHeaderFooter()
  }

  private func layoutVerticalRows(in width: CGFloat, contentHeight: CGFloat) {
    var y: CGFloat = 0
    for (index, button) in rowButtons.enumerated() {
      let height = button.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
      button.frame = CGRect(x: 0, y: y, width: width, height: height)
      y = button.frame.maxY

      if index < separators.count {
        let separatorHeight = FKSelectionControlMetrics.separatorHeight
        separators[index].frame = CGRect(x: 0, y: y, width: width, height: separatorHeight)
        y += separatorHeight
      }
      if index < rowButtons.count - 1 {
        y += configuration.layout.axisSpacing
      }
    }
    contentView.frame = CGRect(x: 0, y: 0, width: width, height: max(y, contentHeight))
    scrollView.contentSize = contentView.frame.size
    scrollView.alwaysBounceHorizontal = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = scrollView.isScrollEnabled
  }

  private func layoutHorizontalRows(in width: CGFloat, height: CGFloat) {
    var x: CGFloat = 0
    for (index, button) in rowButtons.enumerated() {
      let fitted = button.sizeThatFits(CGSize(width: UIView.layoutFittingExpandedSize.width, height: height))
      let buttonWidth = max(fitted.width, 72)
      button.frame = CGRect(x: x, y: 0, width: buttonWidth, height: height)
      x = button.frame.maxX
      if index < rowButtons.count - 1 {
        x += configuration.layout.axisSpacing
      }
    }
    separators.forEach { $0.frame = .zero }
    let contentWidth = max(x, width)
    contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: height)
    scrollView.contentSize = contentView.frame.size
    scrollView.isScrollEnabled = contentWidth > width + 0.5
    scrollView.alwaysBounceHorizontal = scrollView.isScrollEnabled
    scrollView.alwaysBounceVertical = false
    scrollView.showsHorizontalScrollIndicator = scrollView.isScrollEnabled
    scrollView.showsVerticalScrollIndicator = false
  }

  private func layoutWidth() -> CGFloat {
    if bounds.width > 1 { return bounds.width }
    if let superviewWidth = superview?.bounds.width, superviewWidth > 1 {
      return superviewWidth
    }
    return UIScreen.main.bounds.width
  }

  private func stackContentHeight(forWidth width: CGFloat) -> CGFloat {
    if configuration.layout.style == .horizontal {
      return max(configuration.layout.rowMinHeight, rowHeightEstimate())
    }
    guard !rowButtons.isEmpty else { return 0 }
    var height: CGFloat = 0
    for button in rowButtons {
      height += button.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
    height += CGFloat(separators.count) * FKSelectionControlMetrics.separatorHeight
    height += configuration.layout.axisSpacing * CGFloat(max(0, rowButtons.count - 1))
    return height
  }

  private func rowHeightEstimate() -> CGFloat {
    max(
      configuration.layout.rowMinHeight,
      configuration.layout.size.indicatorSide
        + configuration.layout.rowContentInsets.top
        + configuration.layout.rowContentInsets.bottom
    )
  }

  private func measuredHeight(forWidth width: CGFloat) -> CGFloat {
    var height: CGFloat = 0
    if !headerLabel.isHidden {
      height += headerLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
      height += configuration.layout.headerFooterSpacing
    }

    let contentHeight = stackContentHeight(forWidth: width)
    if let maxVisible = configuration.layout.maximumVisibleOptions, configuration.layout.style != .horizontal {
      height += min(contentHeight, rowHeightEstimate() * CGFloat(maxVisible))
    } else {
      height += contentHeight
    }

    if !footerLabel.isHidden {
      height += configuration.layout.headerFooterSpacing
      height += footerLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
    return height
  }

  private func updateAccessibility() {
    accessibilityLabel = configuration.accessibility.groupLabel ?? FKSelectionControlI18n.radioGroupLabel
    if let selected = selectedOption {
      accessibilityValue = selected.accessibilityLabel ?? selected.title
    } else {
      accessibilityValue = nil
    }
    if showsError {
      accessibilityValue = [accessibilityValue, FKSelectionControlI18n.invalidValue]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
  }

  public override var isEnabled: Bool {
    didSet {
      let unique = deduplicatedOptions()
      for (index, button) in rowButtons.enumerated() {
        let optionEnabled = index < unique.count ? unique[index].isEnabled : true
        button.isEnabled = isEnabled && optionEnabled
      }
    }
  }
}
