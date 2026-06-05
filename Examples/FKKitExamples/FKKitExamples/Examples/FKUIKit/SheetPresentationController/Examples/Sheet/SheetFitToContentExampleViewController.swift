import UIKit
import FKUIKit

/// Shows `.fitContent` sizing and how it reacts to runtime content changes.
///
/// Key highlights:
/// - Starts at `.fitContent` and can expand.
/// - Explains why a max height fraction is important (prevents accidental full-screen growth).
final class SheetFitToContentExampleViewController: FKSheetPresentationExamplePageViewController {
  private var maxFitFraction: Float = 0.9
  private var includesExtraBlocks: Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Fit to content",
      subtitle: "A sheet that sizes itself to content with a safety cap.",
      notes: """
      Why a max height matters:
      - Prevents unexpected full-screen expansion when content grows.
      - Keeps the UI “sheet-like” while still being responsive.
      """
    )

    addView(
      FKExampleControls.slider(
        title: "Maximum fitContent height fraction",
        value: maxFitFraction,
        range: 0.4...1.0,
        valueText: { String(format: "%.2f", $0) }
      ) { [weak self] v in
        self?.maxFitFraction = v
      }
    )

    addView(
      FKExampleControls.toggle(
        title: "Include extra content blocks",
        isOn: includesExtraBlocks
      ) { [weak self] isOn in
        self?.includesExtraBlocks = isOn
      }
    )

    addPrimaryButton(title: "Present (shell height)") { [weak self] in
      self?.presentFitContentSheet(contentOnlyReporting: false)
    }

    let contentOnlyButton = UIButton(type: .system)
    contentOnlyButton.configuration = .tinted()
    contentOnlyButton.configuration?.cornerStyle = .large
    contentOnlyButton.setTitle("Present (content-only height)", for: .normal)
    contentOnlyButton.addAction(UIAction { [weak self] _ in
      self?.presentFitContentSheet(contentOnlyReporting: true)
    }, for: .touchUpInside)
    addView(contentOnlyButton)
  }

  private func presentFitContentSheet(contentOnlyReporting: Bool) {
    let content = DynamicBlocksContentViewController(
      includesExtraBlocks: includesExtraBlocks,
      reportsContentOnlyHeight: contentOnlyReporting
    )

    var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
    configuration.sheet.detents = [.fitContent, .full]
    configuration.sheet.maximumFitContentHeightFraction = CGFloat(maxFitFraction)
    configuration.preferredContentSizePolicy = .strict
    if contentOnlyReporting {
      configuration.preferredContentSizeReporting = .contentOnly
    }

    FKSheetPresentationController.present(
      contentController: content,
      from: self,
      configuration: configuration,
      delegate: nil,
      handlers: .init(),
      animated: true,
      completion: nil
    )
  }
}

private final class DynamicBlocksContentViewController: UIViewController {
  private enum Metrics {
    static let horizontalInset: CGFloat = 16
    static let verticalInset: CGFloat = 16
    static let stackSpacing: CGFloat = 12
    static let toggleButtonHeight: CGFloat = 48
    static let extraBlockHeight: CGFloat = 44
    static let extraBlockCount: Int = 8
    static let titleText = "Dynamic content"
    static let subtitleText = "Tap the button below to change the content height."
  }

  private let includesExtraBlocks: Bool
  private let reportsContentOnlyHeight: Bool
  private let scrollView = UIScrollView()
  private let stack = UIStackView()
  private var lastReportedPreferredHeight: CGFloat = 0
  private var lastLayoutWidth: CGFloat = 0
  private var extraBlockCount = 0

  init(includesExtraBlocks: Bool, reportsContentOnlyHeight: Bool = false) {
    self.includesExtraBlocks = includesExtraBlocks
    self.reportsContentOnlyHeight = reportsContentOnlyHeight
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    scrollView.alwaysBounceVertical = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)

    stack.axis = .vertical
    stack.spacing = Metrics.stackSpacing
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)

    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Metrics.horizontalInset),
      stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Metrics.horizontalInset),
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Metrics.verticalInset),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Metrics.verticalInset),
      stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Metrics.horizontalInset * 2),
    ])

    let title = UILabel()
    title.text = Metrics.titleText
    title.font = .preferredFont(forTextStyle: .title2)
    title.numberOfLines = 0

    let subtitle = UILabel()
    subtitle.text = Metrics.subtitleText
    subtitle.numberOfLines = 0
    subtitle.font = .preferredFont(forTextStyle: .body)
    subtitle.textColor = .secondaryLabel

    stack.addArrangedSubview(title)
    stack.addArrangedSubview(subtitle)

    let toggleButton = UIButton(type: .system)
    toggleButton.configuration = .filled()
    toggleButton.configuration?.cornerStyle = .large
    toggleButton.setTitle("Toggle extra blocks", for: .normal)
    toggleButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      toggleButton.heightAnchor.constraint(equalToConstant: Metrics.toggleButtonHeight),
    ])
    toggleButton.addAction(UIAction { [weak self] _ in
      self?.toggleExtraBlocks()
    }, for: .touchUpInside)
    stack.addArrangedSubview(toggleButton)

    applyExtraBlocks(includesExtraBlocks)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard view.bounds.width > 0 else { return }

    let width = view.bounds.width
    if abs(width - lastLayoutWidth) > 0.5 {
      lastLayoutWidth = width
      updatePreferredContentSizeIfNeeded()
    }

    scrollView.isScrollEnabled = scrollView.contentSize.height > scrollView.bounds.height + 1
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    updatePreferredContentSizeIfNeeded(force: true)
  }

  private func toggleExtraBlocks() {
    applyExtraBlocks(extraBlockCount == 0)
  }

  private func applyExtraBlocks(_ includesExtra: Bool) {
    removeExtraBlocks()

    let targetCount = includesExtra ? Metrics.extraBlockCount : 0
    extraBlockCount = targetCount
    updatePreferredContentSizeIfNeeded(force: true)

    guard includesExtra else { return }

    UIView.performWithoutAnimation {
      for idx in 1...Metrics.extraBlockCount {
        stack.addArrangedSubview(makeExtraBlockLabel(index: idx))
      }
    }
  }

  private func removeExtraBlocks() {
    let fixedCount = 3
    while stack.arrangedSubviews.count > fixedCount {
      let view = stack.arrangedSubviews[fixedCount]
      stack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
  }

  private func makeExtraBlockLabel(index: Int) -> UILabel {
    let label = UILabel()
    label.text = "Extra block \(index)"
    label.font = .preferredFont(forTextStyle: .body)
    label.numberOfLines = 1
    label.backgroundColor = .secondarySystemBackground
    label.layer.cornerRadius = 10
    label.layer.masksToBounds = true
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.heightAnchor.constraint(equalToConstant: Metrics.extraBlockHeight),
    ])
    return label
  }

  private func updatePreferredContentSizeIfNeeded(force: Bool = false) {
    let preferredHeight = resolvedPreferredHeight()
    guard force || abs(preferredHeight - lastReportedPreferredHeight) > 0.5 else { return }
    lastReportedPreferredHeight = preferredHeight
    preferredContentSize = CGSize(width: 0, height: preferredHeight)
  }

  private func resolvedPreferredHeight() -> CGFloat {
    let contentHeight = measuredContentHeight(extraBlockCount: extraBlockCount)
    if reportsContentOnlyHeight { return contentHeight }
    return resolvedShellHeight(from: contentHeight)
  }

  private func resolvedFittingWidth() -> CGFloat {
    let viewWidth = view.bounds.width > 0
      ? view.bounds.width
      : (view.window?.bounds.width ?? UIScreen.main.bounds.width)
    return max(220, viewWidth - Metrics.horizontalInset * 2)
  }

  private func measuredContentHeight(extraBlockCount: Int) -> CGFloat {
    let fittingWidth = resolvedFittingWidth()
    let itemCount = 3 + extraBlockCount
    let spacingTotal = CGFloat(max(0, itemCount - 1)) * Metrics.stackSpacing

    let titleHeight = textHeight(Metrics.titleText, font: .preferredFont(forTextStyle: .title2), width: fittingWidth)
    let subtitleHeight = textHeight(Metrics.subtitleText, font: .preferredFont(forTextStyle: .body), width: fittingWidth)
    let stackHeight = titleHeight
      + subtitleHeight
      + Metrics.toggleButtonHeight
      + CGFloat(extraBlockCount) * Metrics.extraBlockHeight
      + spacingTotal

    return stackHeight + Metrics.verticalInset * 2
  }

  private func textHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
    ceil(
      text.boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: font],
        context: nil
      ).height
    )
  }

  private func resolvedShellHeight(from contentHeight: CGFloat) -> CGFloat {
    var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
    configuration.preferredContentSizeReporting = .contentOnly
    return configuration.resolvedShellHeight(
      fromContentHeight: contentHeight,
      layout: .bottomSheet(configuration.sheet),
      containerSafeAreaInsets: effectiveSafeAreaInsetsForSizing()
    )
  }

  private func effectiveSafeAreaInsetsForSizing() -> UIEdgeInsets {
    if let window = view.window, window.safeAreaInsets.bottom > 0 {
      return window.safeAreaInsets
    }
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let keyWindow = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
    return keyWindow?.safeAreaInsets ?? .zero
  }
}
