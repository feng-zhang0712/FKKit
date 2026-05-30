import UIKit

@MainActor
struct FKCalloutInteractionHandlers {
  var actionHandlers: [String: () -> Void] = [:]
  var menuSelectionHandler: ((FKCalloutMenuItem) -> Void)?
  var closeHandler: (() -> Void)?
  var onDismissAfterInteraction: ((FKCalloutDismissReason) -> Void)?
}

final class FKCalloutBubbleView: UIView {
  private let chromeRenderer = FKCalloutBubbleChromeRenderer()
  private let contentContainer = UIView()
  private let titleLabel = UILabel()
  private let messageLabel = UILabel()
  private let textStack = UIStackView()
  private var textStackConstraints: [NSLayoutConstraint] = []
  private var headerFillColor: UIColor?

  private var metrics = FKCalloutBeakGeometry.LayoutMetrics(
    beakEdge: .bottom,
    beakCenterAlongEdge: 0,
    beakWidth: 14,
    beakHeight: 7,
    cornerRadius: 8
  )

  private(set) var configuration: FKCalloutConfiguration
  private(set) var content: FKCalloutContent
  private var handlers = FKCalloutInteractionHandlers()
  /// Mounted custom content, reused for sizing during relayout.
  private(set) var mountedCustomView: UIView?

  private var customBeakViewProvider: (@MainActor () -> UIView)?
  private var mountedCustomBeakView: UIView?

  init(
    configuration: FKCalloutConfiguration,
    content: FKCalloutContent,
    handlers: FKCalloutInteractionHandlers = .init(),
    customBeakViewProvider: (@MainActor () -> UIView)? = nil
  ) {
    self.configuration = configuration
    self.content = content
    self.handlers = handlers
    self.customBeakViewProvider = customBeakViewProvider
    super.init(frame: .zero)
    isAccessibilityElement = true
    accessibilityTraits = .staticText
    backgroundColor = .clear
    textStack.axis = .vertical
    textStack.spacing = 4
    textStack.alignment = .fill
    textStack.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0
    messageLabel.numberOfLines = 0
    titleLabel.lineBreakMode = .byWordWrapping
    messageLabel.lineBreakMode = .byWordWrapping
    contentContainer.translatesAutoresizingMaskIntoConstraints = false
    contentContainer.clipsToBounds = true
    addSubview(contentContainer)
    chromeRenderer.install(on: self, below: contentContainer)
    applyContent()
    applyTypography()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  func update(
    configuration: FKCalloutConfiguration,
    content: FKCalloutContent,
    handlers: FKCalloutInteractionHandlers = .init(),
    customBeakViewProvider: (@MainActor () -> UIView)? = nil
  ) {
    self.configuration = configuration
    self.content = content
    self.handlers = handlers
    self.customBeakViewProvider = customBeakViewProvider
    mountedCustomBeakView?.removeFromSuperview()
    mountedCustomBeakView = nil
    applyContent()
    applyTypography()
    setNeedsLayout()
  }

  func updateMetrics(beakCenterAlongEdge: CGFloat, placement: FKCalloutPlacement) {
    metrics = FKCalloutBeakGeometry.LayoutMetrics(
      beakEdge: placement.beakEdge,
      beakCenterAlongEdge: beakCenterAlongEdge,
      beakWidth: configuration.appearance.beakWidth,
      beakHeight: configuration.appearance.beakHeight,
      cornerRadius: configuration.appearance.cornerRadius,
      beakStyle: configuration.appearance.beakStyle
    )
    setNeedsLayout()
  }

  static func preferredSize(
    for content: FKCalloutContent,
    configuration: FKCalloutConfiguration,
    maxWidth: CGFloat,
    minWidth: CGFloat = 0,
    customViewProvider: (@MainActor () -> UIView)? = nil,
    mountedCustomView: UIView? = nil
  ) -> CGSize {
    let metrics = FKCalloutBeakGeometry.LayoutMetrics(
      beakEdge: configuration.placement.beakEdge,
      beakCenterAlongEdge: 0,
      beakWidth: configuration.appearance.beakWidth,
      beakHeight: configuration.appearance.beakHeight,
      cornerRadius: configuration.appearance.cornerRadius,
      beakStyle: configuration.appearance.beakStyle
    )
    let insets = FKCalloutBeakGeometry.contentLayoutGuideInsets(
      bubbleBounds: CGRect(x: 0, y: 0, width: maxWidth, height: 10_000),
      metrics: metrics,
      contentInsets: configuration.contentInsets
    )
    let contentLimit = maxWidth - insets.left - insets.right
    let measured: CGSize
    switch content {
    case let .message(text):
      measured = textSize(text, font: configuration.font, width: contentLimit)
    case let .titleSubtitle(title, message):
      let titleSize = textSize(title, font: configuration.titleFont, width: contentLimit)
      let bodySize = textSize(message, font: configuration.font, width: contentLimit)
      measured = CGSize(width: max(titleSize.width, bodySize.width), height: titleSize.height + 4 + bodySize.height)
    case let .iconMessage(_, message):
      let body = textSize(message, font: configuration.font, width: contentLimit - 28)
      measured = CGSize(width: body.width + 28, height: body.height)
    case let .messageWithActions(message, actions):
      let body = textSize(message, font: configuration.font, width: contentLimit)
      let footerHeight = actions.isEmpty ? 0 : measuredFooterActionsHeight(actions)
      measured = CGSize(
        width: min(contentLimit, max(body.width, 1)),
        height: body.height + (actions.isEmpty ? 0 : 12 + footerHeight)
      )
    case let .headerPanel(header, body):
      let cardPadding: CGFloat = 12
      let headerCardHeight: CGFloat = 40
      let sectionSpacing: CGFloat = 12
      let bodyLimit = max(1, contentLimit)
      let bodySize = textSize(body, font: configuration.font, width: bodyLimit)
      let headerTitleLimit = max(1, bodyLimit - cardPadding * 2)
      let headerTitleWidth = ceil((header.title as NSString).boundingRect(
        with: CGSize(width: headerTitleLimit, height: headerCardHeight),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: UIFont.systemFont(ofSize: configuration.titleFont.pointSize, weight: .semibold)],
        context: nil
      ).width + cardPadding * 2)
      let panelWidth = min(contentLimit, max(bodySize.width, headerTitleWidth))
      measured = CGSize(
        width: panelWidth,
        height: headerCardHeight + sectionSpacing + bodySize.height
      )
    case let .coachMark(payload):
      measured = FKCalloutCoachMarkView.preferredSize(
        content: payload,
        configuration: configuration,
        maxWidth: contentLimit
      )
    case let .menu(menu):
      let resolvedMin = max(minWidth, configuration.minWidth ?? 0)
      return FKCalloutMenuView.preferredSize(
        menu: menu,
        configuration: configuration,
        maxWidth: maxWidth,
        minWidth: resolvedMin
      )
    case .customView:
      if let mountedCustomView {
        measured = measureCustomView(mountedCustomView, contentLimit: contentLimit)
      } else if let provider = customViewProvider {
        measured = measureCustomView(provider(), contentLimit: contentLimit)
      } else {
        measured = CGSize(width: min(180, contentLimit), height: 44)
      }
    }
    let resolvedMin = configuration.minWidth ?? minWidth
    let contentWidth = min(contentLimit, max(measured.width, 1))
    let width = min(maxWidth, max(resolvedMin, contentWidth + insets.left + insets.right))
    let contentHeight = Self.cappedContentHeight(measured.height, configuration: configuration)
    return CGSize(width: ceil(width), height: ceil(contentHeight + insets.top + insets.bottom))
  }

  private static func cappedContentHeight(_ height: CGFloat, configuration: FKCalloutConfiguration) -> CGFloat {
    guard let maxContentHeight = configuration.maxContentHeight, maxContentHeight > 0 else {
      return height
    }
    return min(height, maxContentHeight)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    guard bounds.width > 0, bounds.height > 0 else { return }

    let usesCustomBeak = customBeakViewProvider != nil
    headerFillColor = nil
    chromeRenderer.apply(
      on: self,
      below: contentContainer,
      bounds: bounds,
      metrics: metrics,
      configuration: configuration,
      content: content,
      traitCollection: traitCollection,
      usesCustomBeak: usesCustomBeak,
      headerFillColor: headerFillColor
    )

    contentContainer.frame = bounds.inset(
      by: FKCalloutBeakGeometry.contentLayoutGuideInsets(
        bubbleBounds: bounds,
        metrics: metrics,
        contentInsets: configuration.contentInsets
      )
    )
    applyContentLayoutWidths()
    layoutCustomBeakView()
    mountedCustomView?.setNeedsLayout()
    mountedCustomView?.layoutIfNeeded()
    updateAccessibilityLabel()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    applyTypography()
    setNeedsLayout()
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard bounds.width > 0 else { return false }
    let includesBeak = customBeakViewProvider == nil
    let path = chromeRenderer.unifiedPath(bounds: bounds, metrics: metrics, includesBeak: includesBeak)
    if path.contains(point) { return true }
    if let beakView = mountedCustomBeakView, !beakView.isHidden, beakView.alpha > 0.01 {
      let local = convert(point, to: beakView)
      return beakView.point(inside: local, with: event)
    }
    return false
  }

  private func applyContent() {
    let reusableCustomView: UIView? = {
      if case .customView = content, let mountedCustomView, mountedCustomView.superview == contentContainer {
        return mountedCustomView
      }
      return nil
    }()

    contentContainer.subviews.forEach { subview in
      if subview !== reusableCustomView {
        subview.removeFromSuperview()
      }
    }
    textStack.arrangedSubviews.forEach { textStack.removeArrangedSubview($0); $0.removeFromSuperview() }
    NSLayoutConstraint.deactivate(textStackConstraints)
    textStackConstraints = []
    headerFillColor = nil
    if reusableCustomView == nil {
      mountedCustomView = nil
    }
    isAccessibilityElement = true

    switch content {
    case let .message(text):
      messageLabel.text = text
      textStack.addArrangedSubview(messageLabel)
      contentContainer.addSubview(textStack)
      textStackConstraints = activateStackConstraints()
    case let .titleSubtitle(title, message):
      titleLabel.text = title
      messageLabel.text = message
      titleLabel.font = .systemFont(ofSize: configuration.titleFont.pointSize, weight: .semibold)
      messageLabel.textColor = configuration.appearance.resolvedSecondaryTextColor(traitCollection: traitCollection)
      textStack.addArrangedSubview(titleLabel)
      textStack.addArrangedSubview(messageLabel)
      contentContainer.addSubview(textStack)
      textStackConstraints = activateStackConstraints()
    case let .iconMessage(icon, message):
      mountFullSize(buildIconRow(icon: icon, message: message))
    case let .messageWithActions(message, actions):
      mountFullSize(buildActionsLayout(message: message, actions: actions))
    case let .headerPanel(header, body):
      mountFullSize(buildHeaderLayout(header: header, body: body))
    case let .coachMark(payload):
      mountFullSize(buildCoachMark(payload))
    case let .menu(menu):
      isAccessibilityElement = false
      mountFullSize(buildMenu(menu))
    case let .customView(provider):
      if let reusableCustomView {
        mountedCustomView = reusableCustomView
      } else {
        let view = provider()
        mountedCustomView = view
        mountFullSize(view)
      }
    }
  }

  private func actionHandler(for action: FKCalloutAction) -> (() -> Void)? {
    handlers.actionHandlers[action.id] ?? handlers.actionHandlers[action.title]
  }

  private func actionHandler(forKey key: String) -> (() -> Void)? {
    handlers.actionHandlers[key]
  }

  private func layoutCustomBeakView() {
    guard let provider = customBeakViewProvider else {
      mountedCustomBeakView?.removeFromSuperview()
      mountedCustomBeakView = nil
      return
    }
    let beakView = mountedCustomBeakView ?? {
      let view = provider()
      addSubview(view)
      mountedCustomBeakView = view
      return view
    }()
    beakView.frame = FKCalloutBeakGeometry.beakFrame(bounds: bounds, metrics: metrics)
    bringSubviewToFront(beakView)
  }

  private func mountFullSize(_ view: UIView) {
    if let maxHeight = configuration.maxContentHeight, maxHeight > 0 {
      mountScrollableContent(view, maxHeight: maxHeight)
      return
    }
    view.translatesAutoresizingMaskIntoConstraints = false
    contentContainer.addSubview(view)
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
      view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
      view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
    ])
  }

  private func mountScrollableContent(_ view: UIView, maxHeight: CGFloat) {
    let scrollView = UIScrollView()
    scrollView.showsVerticalScrollIndicator = true
    scrollView.alwaysBounceVertical = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(view)
    contentContainer.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
      scrollView.heightAnchor.constraint(equalToConstant: maxHeight),
      view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
    ])
  }

  private func activateStackConstraints() -> [NSLayoutConstraint] {
    let constraints = [
      textStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
      textStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
      textStack.topAnchor.constraint(equalTo: contentContainer.topAnchor),
      textStack.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
    return constraints
  }

  private func buildIconRow(icon: FKCalloutIcon, message: String) -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .top
    row.spacing = 10
    let iconView = UIImageView(image: icon.image ?? icon.symbolName.flatMap { UIImage(systemName: $0) })
    iconView.tintColor = icon.tintColor ?? configuration.appearance.resolvedTextColor(traitCollection: traitCollection)
    iconView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([iconView.widthAnchor.constraint(equalToConstant: 18), iconView.heightAnchor.constraint(equalToConstant: 18)])
    let label = UILabel()
    label.font = configuration.font
    label.textColor = configuration.appearance.resolvedTextColor(traitCollection: traitCollection)
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    label.setContentHuggingPriority(.defaultLow, for: .horizontal)
    label.text = message
    row.addArrangedSubview(iconView)
    row.addArrangedSubview(label)
    return row
  }

  private func buildActionsLayout(message: String, actions: [FKCalloutAction]) -> UIView {
    let root = UIView()
    let label = UILabel()
    label.font = configuration.font
    label.textColor = configuration.appearance.resolvedTextColor(traitCollection: traitCollection)
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.text = message
    label.translatesAutoresizingMaskIntoConstraints = false
    let footer = UIStackView()
    footer.axis = .horizontal
    footer.alignment = .center
    footer.setContentHuggingPriority(.required, for: .vertical)
    footer.setContentCompressionResistancePriority(.required, for: .vertical)
    footer.translatesAutoresizingMaskIntoConstraints = false
    footer.addArrangedSubview(UIView())
    actions.forEach { footer.addArrangedSubview(makeActionButton($0)) }
    root.addSubview(label)
    root.addSubview(footer)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      label.topAnchor.constraint(equalTo: root.topAnchor),
      footer.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      footer.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      footer.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
      root.bottomAnchor.constraint(equalTo: footer.bottomAnchor),
    ])
    return root
  }

  private func buildHeaderLayout(header: FKCalloutHeaderPanel, body: String) -> UIView {
    let root = UIView()
    let headerColor = header.resolvedBackgroundColor(style: configuration.appearance.style, traitCollection: traitCollection)
    let headerCard = UIView()
    headerCard.backgroundColor = headerColor
    headerCard.translatesAutoresizingMaskIntoConstraints = false
    headerCard.layer.cornerRadius = min(configuration.appearance.cornerRadius, 10)
    headerCard.layer.masksToBounds = true
    let headerLabel = UILabel()
    headerLabel.font = .systemFont(ofSize: configuration.titleFont.pointSize, weight: .semibold)
    headerLabel.textColor = header.resolvedTextColor(style: configuration.appearance.style, traitCollection: traitCollection)
    headerLabel.text = header.title
    headerLabel.numberOfLines = 0
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    let bodyLabel = UILabel()
    bodyLabel.font = configuration.font
    bodyLabel.textColor = configuration.appearance.resolvedSecondaryTextColor(traitCollection: traitCollection)
    bodyLabel.numberOfLines = 0
    bodyLabel.lineBreakMode = .byWordWrapping
    bodyLabel.text = body
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
    headerCard.addSubview(headerLabel)
    root.addSubview(headerCard)
    root.addSubview(bodyLabel)
    NSLayoutConstraint.activate([
      headerCard.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      headerCard.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      headerCard.topAnchor.constraint(equalTo: root.topAnchor),
      headerCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
      headerLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 12),
      headerLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -12),
      headerLabel.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 10),
      headerLabel.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -10),

      bodyLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      bodyLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      bodyLabel.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 12),
      bodyLabel.bottomAnchor.constraint(equalTo: root.bottomAnchor),
    ])
    return root
  }

  private func buildCoachMark(_ payload: FKCalloutCoachMarkContent) -> UIView {
    let view = FKCalloutCoachMarkView(content: payload, configuration: configuration)
    view.onPrimaryAction = { [weak self] in
      self?.actionHandler(forKey: payload.primaryActionTitle)?()
      self?.handlers.onDismissAfterInteraction?(.actionTriggered)
    }
    view.onClose = { [weak self] in
      self?.handlers.closeHandler?()
      self?.handlers.onDismissAfterInteraction?(.closeButton)
    }
    return view
  }

  private func buildMenu(_ menu: FKCalloutMenu) -> UIView {
    let view = FKCalloutMenuView(menu: menu, configuration: configuration)
    view.onSelectItem = { [weak self] item in
      guard item.isEnabled else { return }
      self?.handlers.menuSelectionHandler?(item)
      self?.handlers.onDismissAfterInteraction?(.menuSelection)
    }
    return view
  }

  private func makeActionButton(_ action: FKCalloutAction) -> UIButton {
    let button = UIButton(type: .system)
    var config: UIButton.Configuration = action.style == .primary ? .filled() : .gray()
    config.title = action.title
    config.cornerStyle = .medium
    config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
    if action.style == .primary {
      config.baseBackgroundColor = .label
      config.baseForegroundColor = .systemBackground
    }
    button.configuration = config
    button.accessibilityLabel = action.accessibilityLabel ?? action.title
    button.addAction(UIAction { [weak self] _ in
      self?.actionHandler(for: action)?()
      self?.handlers.onDismissAfterInteraction?(.actionTriggered)
    }, for: .touchUpInside)
    return button
  }

  private func applyTypography() {
    messageLabel.font = configuration.font
    messageLabel.textColor = configuration.appearance.resolvedTextColor(traitCollection: traitCollection)
    titleLabel.font = configuration.titleFont
    titleLabel.textColor = configuration.appearance.resolvedTextColor(traitCollection: traitCollection)
  }

  private func updateAccessibilityLabel() {
    if let override = configuration.accessibilityAnnouncementOverride {
      accessibilityLabel = override
      return
    }
    switch content {
    case let .message(text): accessibilityLabel = text
    case let .titleSubtitle(title, message): accessibilityLabel = "\(title). \(message)"
    case let .iconMessage(_, message): accessibilityLabel = message
    case let .messageWithActions(message, _): accessibilityLabel = message
    case let .headerPanel(header, body): accessibilityLabel = "\(header.title). \(body)"
    case let .coachMark(payload): accessibilityLabel = "\(payload.title). \(payload.message)"
    case .menu, .customView: accessibilityLabel = "Popover content"
    }
  }

  private func applyContentLayoutWidths() {
    let width = contentContainer.bounds.width
    guard width > 0 else { return }

    switch content {
    case .message, .titleSubtitle:
      messageLabel.preferredMaxLayoutWidth = width
      titleLabel.preferredMaxLayoutWidth = width
    case .iconMessage:
      applyLabelLayoutWidths(in: contentContainer, width: width, iconRowTextInset: 28)
    case .messageWithActions, .headerPanel, .coachMark, .menu, .customView:
      applyLabelLayoutWidths(in: contentContainer, width: width, iconRowTextInset: 28)
    }
  }

  private func applyLabelLayoutWidths(in view: UIView, width: CGFloat, iconRowTextInset: CGFloat) {
    if let label = view as? UILabel {
      label.numberOfLines = 0
      label.lineBreakMode = .byWordWrapping
      if let row = label.superview as? UIStackView, row.axis == .horizontal, row.arrangedSubviews.contains(label) {
        label.preferredMaxLayoutWidth = max(1, width - iconRowTextInset)
      } else {
        label.preferredMaxLayoutWidth = width
      }
    }
    for subview in view.subviews {
      applyLabelLayoutWidths(in: subview, width: width, iconRowTextInset: iconRowTextInset)
    }
  }

  private static func measureCustomView(_ view: UIView, contentLimit: CGFloat) -> CGSize {
    let intrinsic = view.intrinsicContentSize
    let hasIntrinsicHeight = intrinsic.height != UIView.noIntrinsicMetric && intrinsic.height > 0
    let hasIntrinsicWidth = intrinsic.width != UIView.noIntrinsicMetric && intrinsic.width > 0
    if hasIntrinsicHeight {
      let width = hasIntrinsicWidth ? min(intrinsic.width, contentLimit) : contentLimit
      return CGSize(width: max(width, 1), height: intrinsic.height)
    }

    if view.bounds.width > 0, view.bounds.height > 0 {
      return CGSize(
        width: min(view.bounds.width, contentLimit),
        height: view.bounds.height
      )
    }

    // Avoid measuring against a zero-sized superview; detached views only.
    guard view.superview == nil else {
      let fallback = view.sizeThatFits(CGSize(width: contentLimit, height: UIView.layoutFittingExpandedSize.height))
      return CGSize(
        width: min(max(fallback.width, 1), contentLimit),
        height: max(fallback.height, 1)
      )
    }

    let widthConstraint = view.widthAnchor.constraint(equalToConstant: contentLimit)
    widthConstraint.priority = .required
    widthConstraint.isActive = true
    view.setNeedsLayout()
    view.layoutIfNeeded()
    let size = view.systemLayoutSizeFitting(
      CGSize(width: contentLimit, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    widthConstraint.isActive = false
    return CGSize(
      width: min(max(size.width, 1), contentLimit),
      height: max(size.height, 1)
    )
  }

  private static func measuredFooterActionsHeight(_ actions: [FKCalloutAction]) -> CGFloat {
    actions.map { action in
      var config: UIButton.Configuration = action.style == .primary ? .filled() : .gray()
      config.title = action.title
      config.cornerStyle = .medium
      config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
      return UIButton(configuration: config).intrinsicContentSize.height
    }.max() ?? 0
  }

  private static func textSize(_ text: String, font: UIFont, width: CGFloat) -> CGSize {
    let limit = max(1, width)
    let label = UILabel()
    label.font = font
    label.text = text
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.preferredMaxLayoutWidth = limit
    return label.sizeThatFits(CGSize(width: limit, height: .greatestFiniteMagnitude))
  }
}
