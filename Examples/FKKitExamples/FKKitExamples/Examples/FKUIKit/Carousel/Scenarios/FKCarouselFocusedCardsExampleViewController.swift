import FKUIKit
import UIKit

/// Interactive playground for focused-card layout, taps, and motion tuning.
final class FKCarouselFocusedCardsExampleViewController: FKCarouselExampleScrollViewController {
  private let carousel = FKCarousel()
  private let statusLabel = UILabel()

  private let pageWidthSlider = UISlider()
  private let heightSlider = UISlider()
  private let spacingSlider = UISlider()
  private let scaleSlider = UISlider()
  private let activeLineSlider = UISlider()
  private let inactiveLineSlider = UISlider()
  private let cornerRadiusSlider = UISlider()

  private let pageWidthValue = UILabel()
  private let heightValue = UILabel()
  private let spacingValue = UILabel()
  private let scaleValue = UILabel()
  private let activeLineValue = UILabel()
  private let inactiveLineValue = UILabel()
  private let cornerRadiusValue = UILabel()

  private let decelerationControl = UISegmentedControl(items: ["Fast", "Normal"])
  private let bounceSwitch = UISwitch()
  private let loopSwitch = UISwitch()
  private let autoScrollSwitch = UISwitch()
  private let indicatorTapSwitch = UISwitch()
  private let sideCardTapSwitch = UISwitch()

  private var cardCornerRadius: CGFloat = 16

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Focused cards"
    installScrollRootChrome()
    configureControls()
    configureCarousel()
    buildUI()
    applyConfiguration(reloadPages: true)
  }

  private func configureCarousel() {
    carousel.pageProvider = { [weak self] item, bounds in
      FKCarouselExampleSupport.makeFocusedImageCardPage(
        item: item,
        bounds: bounds,
        cornerRadius: self?.cardCornerRadius ?? 16
      )
    }
    carousel.callbacks.onPageChanged = { [weak self] index, reason in
      self?.refreshStatus(reason: reason, page: index)
    }
    carousel.callbacks.onPageSelected = { [weak self] index in
      guard let self else { return }
      self.refreshStatus(reason: nil, page: self.carousel.currentPageIndex, selected: index)
    }
    carousel.setItems(FKCarouselExampleSupport.focusedCardItems())
  }

  private func configureControls() {
    configureSlider(pageWidthSlider, min: 200, max: 340, value: 280, valueLabel: pageWidthValue)
    configureSlider(heightSlider, min: 120, max: 260, value: 180, valueLabel: heightValue)
    configureSlider(spacingSlider, min: 0, max: 28, value: 14, valueLabel: spacingValue)
    configureSlider(scaleSlider, min: 0.70, max: 1.0, value: 0.88, valueLabel: scaleValue, format: "%.2f")
    configureSlider(activeLineSlider, min: 8, max: 36, value: 22, valueLabel: activeLineValue)
    configureSlider(inactiveLineSlider, min: 4, max: 20, value: 8, valueLabel: inactiveLineValue)
    configureSlider(cornerRadiusSlider, min: 0, max: 28, value: 16, valueLabel: cornerRadiusValue)

    decelerationControl.selectedSegmentIndex = 0
    bounceSwitch.isOn = false
    loopSwitch.isOn = true
    autoScrollSwitch.isOn = false
    indicatorTapSwitch.isOn = true
    sideCardTapSwitch.isOn = true

    let reloadAction = UIAction { [weak self] _ in self?.applyConfiguration(reloadPages: false) }
    let reloadPagesAction = UIAction { [weak self] _ in self?.applyConfiguration(reloadPages: true) }

    for slider in [
      pageWidthSlider, heightSlider, spacingSlider, scaleSlider,
      activeLineSlider, inactiveLineSlider,
    ] {
      slider.addAction(reloadAction, for: .valueChanged)
    }
    cornerRadiusSlider.addAction(reloadPagesAction, for: .valueChanged)
    decelerationControl.addAction(reloadAction, for: .valueChanged)
    for toggle in [bounceSwitch, loopSwitch, autoScrollSwitch, indicatorTapSwitch, sideCardTapSwitch] {
      toggle.addAction(reloadAction, for: .valueChanged)
    }

    statusLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
  }

  private func buildUI() {
    contentStack.addArrangedSubview(carousel)
    contentStack.addArrangedSubview(statusLabel)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("Layout"))
    contentStack.addArrangedSubview(makeSliderRow(title: "Page width", slider: pageWidthSlider, valueLabel: pageWidthValue))
    contentStack.addArrangedSubview(makeSliderRow(title: "Height", slider: heightSlider, valueLabel: heightValue))
    contentStack.addArrangedSubview(makeSliderRow(title: "Spacing", slider: spacingSlider, valueLabel: spacingValue))
    contentStack.addArrangedSubview(makeSliderRow(title: "Side scale", slider: scaleSlider, valueLabel: scaleValue))
    contentStack.addArrangedSubview(makeSliderRow(title: "Corner radius", slider: cornerRadiusSlider, valueLabel: cornerRadiusValue))

    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("Indicator"))
    contentStack.addArrangedSubview(makeSliderRow(title: "Active line width", slider: activeLineSlider, valueLabel: activeLineValue))
    contentStack.addArrangedSubview(makeSliderRow(title: "Inactive line width", slider: inactiveLineSlider, valueLabel: inactiveLineValue))
    contentStack.addArrangedSubview(makeToggleRow(title: "Tap indicator to jump", toggle: indicatorTapSwitch))

    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("Interaction & motion"))
    contentStack.addArrangedSubview(makeToggleRow(title: "Tap side card to jump", toggle: sideCardTapSwitch))
    contentStack.addArrangedSubview(makeLabeledControl(title: "Deceleration", control: decelerationControl))
    contentStack.addArrangedSubview(makeToggleRow(title: "Bounces", toggle: bounceSwitch))
    contentStack.addArrangedSubview(makeToggleRow(title: "Infinite loop", toggle: loopSwitch))
    contentStack.addArrangedSubview(makeToggleRow(title: "Auto-scroll", toggle: autoScrollSwitch))

    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      """
      Image-only cards via pageProvider. Tune fixedPageWidth, height, interPageSpacing, \
      sidePageScale, line indicator widths, decelerationRate, bounces, loop, and tap behaviors live.
      """
    ))
  }

  private func applyConfiguration(reloadPages: Bool) {
    let pageWidth = CGFloat(pageWidthSlider.value.rounded())
    let height = CGFloat(heightSlider.value.rounded())
    let spacing = CGFloat(spacingSlider.value.rounded())
    let scale = CGFloat(scaleSlider.value)
    let activeLine = CGFloat(activeLineSlider.value.rounded())
    let inactiveLine = CGFloat(inactiveLineSlider.value.rounded())
    cardCornerRadius = CGFloat(cornerRadiusSlider.value.rounded())

    pageWidthValue.text = "\(Int(pageWidth))"
    heightValue.text = "\(Int(height))"
    spacingValue.text = "\(Int(spacing))"
    scaleValue.text = String(format: "%.2f", scale)
    activeLineValue.text = "\(Int(activeLine))"
    inactiveLineValue.text = "\(Int(inactiveLine))"
    cornerRadiusValue.text = "\(Int(cardCornerRadius))"

    var config = FKCarouselPresets.focusedCards(
      pageWidth: pageWidth,
      height: height,
      interPageSpacing: spacing,
      sidePageScale: scale
    )
    config.paging.decelerationRate = decelerationControl.selectedSegmentIndex == 0 ? .fast : .normal
    config.paging.bounces = bounceSwitch.isOn
    config.layout.isInfiniteLoopEnabled = loopSwitch.isOn
    config.autoScroll.isEnabled = autoScrollSwitch.isOn
    config.autoScroll.interval = 3.0
    config.indicator.allowsPageSelection = indicatorTapSwitch.isOn
    config.indicator.activeLineWidth = activeLine
    config.indicator.inactiveLineWidth = inactiveLine
    config.interaction.scrollsToTappedPage = sideCardTapSwitch.isOn

    carousel.apply(configuration: config)

    if reloadPages {
      carousel.setItems(FKCarouselExampleSupport.focusedCardItems(), preservingIndex: true)
    }

    carousel.invalidateIntrinsicContentSize()
    view.setNeedsLayout()
    view.layoutIfNeeded()
    refreshStatus(reason: nil, page: carousel.currentPageIndex)
  }

  private func refreshStatus(
    reason: FKCarouselPageChangeReason?,
    page: Int,
    selected: Int? = nil
  ) {
    let reasonText = reason.map { String(describing: $0) } ?? "—"
    let selectedText = selected.map { String($0) } ?? "—"
    statusLabel.text = """
    page: \(page)/\(max(0, carousel.pageCount - 1)) · reason: \(reasonText) · selected: \(selectedText)
    width \(Int(pageWidthSlider.value)) · height \(Int(heightSlider.value)) · spacing \(Int(spacingSlider.value)) · scale \(String(format: "%.2f", scaleSlider.value))
    """
  }

  private func configureSlider(
    _ slider: UISlider,
    min: Float,
    max: Float,
    value: Float,
    valueLabel: UILabel,
    format: String = "%.0f"
  ) {
    slider.minimumValue = min
    slider.maximumValue = max
    slider.value = value
    valueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    valueLabel.textColor = .secondaryLabel
    valueLabel.textAlignment = .right
    valueLabel.setContentHuggingPriority(.required, for: .horizontal)
    valueLabel.text = String(format: format, value)
  }

  private func makeSliderRow(title: String, slider: UISlider, valueLabel: UILabel) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .subheadline)
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    let top = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
    top.axis = .horizontal
    top.distribution = .fill

    let column = UIStackView(arrangedSubviews: [top, slider])
    column.axis = .vertical
    column.spacing = 4
    return column
  }

  private func makeToggleRow(title: String, toggle: UISwitch) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    let row = UIStackView(arrangedSubviews: [label, toggle])
    row.axis = .horizontal
    row.alignment = .center
    row.distribution = .equalSpacing
    return row
  }

  private func makeLabeledControl(title: String, control: UIView) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    let column = UIStackView(arrangedSubviews: [label, control])
    column.axis = .vertical
    column.spacing = 6
    return column
  }
}
