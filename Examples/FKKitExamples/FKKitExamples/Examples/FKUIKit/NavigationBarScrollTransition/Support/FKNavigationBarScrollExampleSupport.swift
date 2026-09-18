import FKUIKit
import UIKit

/// Shared UI helpers for FKNavigationBarScrollTransition demos.
enum FKNavigationBarScrollExampleUI {
  static let defaultHeroHeight: CGFloat = 220

  static func caption(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    return label
  }

  static func headline(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    return label
  }

  static func statusLabel() -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = "progress=0.00"
    return label
  }

  static func makeButton(_ title: String, action: @escaping () -> Void) -> UIButton {
    var config = UIButton.Configuration.bordered()
    config.title = title
    let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }

  static func makeFillerBlock(index: Int, height: CGFloat = 72) -> UIView {
    let view = UIView()
    view.backgroundColor = index.isMultiple(of: 2) ? .secondarySystemBackground : .tertiarySystemBackground
    view.layer.cornerRadius = 10
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalToConstant: height).isActive = true

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "Content block \(index + 1)"
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    return view
  }

  static func makeHeroView(
    title: String,
    height: CGFloat = defaultHeroHeight,
    topColor: UIColor = .systemIndigo,
    bottomColor: UIColor = .systemPurple
  ) -> FKNavigationBarScrollExampleHeroView {
    let hero = FKNavigationBarScrollExampleHeroView(
      title: title,
      topColor: topColor,
      bottomColor: bottomColor
    )
    hero.translatesAutoresizingMaskIntoConstraints = false
    hero.heightAnchor.constraint(equalToConstant: height).isActive = true
    return hero
  }

  static func formatProgress(_ engine: FKNavigationBarScrollEngine) -> String {
    let value = engine.progress.value
    let forced = engine.forcedProgress.map { String(format: " forced=%.2f", $0) } ?? ""
    let bg = engine.resolvedAppearance.backgroundAlpha
    let titleA = engine.resolvedAppearance.titleAlpha
    return String(
      format: "progress=%.2f bgα=%.2f titleα=%.2f%@  status=%@",
      value,
      bg,
      titleA,
      forced,
      String(describing: engine.resolvedStatusBarStyle)
    )
  }
}

/// Gradient hero used as the scroll-range reference for demos.
final class FKNavigationBarScrollExampleHeroView: UIView {
  private let gradientLayer = CAGradientLayer()
  private let titleLabel = UILabel()

  init(title: String, topColor: UIColor, bottomColor: UIColor) {
    super.init(frame: .zero)
    clipsToBounds = true

    gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    layer.insertSublayer(gradientLayer, at: 0)

    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .title1)
    titleLabel.textColor = .white
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer.frame = bounds
  }
}

/// Scroll page with a full-bleed hero under a transparent navigation bar.
///
/// Content extends under the system bar so scroll-driven chrome transitions are visible.
class FKNavigationBarScrollExampleHeroPageViewController: UIViewController, UIScrollViewDelegate {
  let scrollView = UIScrollView()
  let contentStack = UIStackView()
  let statusLabel = FKNavigationBarScrollExampleUI.statusLabel()
  private let actionsStack = UIStackView()

  private(set) var heroView: FKNavigationBarScrollExampleHeroView!
  private(set) var heroHeight: CGFloat = FKNavigationBarScrollExampleUI.defaultHeroHeight

  /// Cached style returned from ``preferredStatusBarStyle``.
  var cachedStatusBarStyle: UIStatusBarStyle = .lightContent

  /// When `true`, this page becomes `scrollView.delegate` (manual observation demos).
  var becomesScrollViewDelegate: Bool { false }

  var heroTitle: String { "Hero" }

  override var preferredStatusBarStyle: UIStatusBarStyle { cachedStatusBarStyle }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    edgesForExtendedLayout = [.all]
    extendedLayoutIncludesOpaqueBars = true
    // Request underlap before the first navigation-controller layout pass.
    navigationController?.navigationBar.isTranslucent = true

    heroView = FKNavigationBarScrollExampleUI.makeHeroView(title: heroTitle, height: heroHeight)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.contentInset.bottom = 48
    scrollView.verticalScrollIndicatorInsets.bottom = 48
    if #available(iOS 26.0, *) {
      // System scroll-edge glass fights custom transparent nav chrome.
      scrollView.topEdgeEffect.isHidden = true
    }
    if becomesScrollViewDelegate {
      scrollView.delegate = self
    }
    view.addSubview(scrollView)

    contentStack.axis = .vertical
    contentStack.alignment = .fill
    contentStack.spacing = 12
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    statusLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
    view.addSubview(statusLabel)

    actionsStack.axis = .vertical
    actionsStack.spacing = 8
    actionsStack.isLayoutMarginsRelativeArrangement = true
    actionsStack.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])

    contentStack.addArrangedSubview(heroView)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.prefersLargeTitles = false
    prepareTransparentNavigationUnderlap()
    setNeedsStatusBarAppearanceUpdate()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    prepareTransparentNavigationUnderlap()
    scrollView.fk_reloadNavigationBarScroll()
  }

  /// Ensures the shared bar is translucent and the child view fills under it (hero can show through).
  private func prepareTransparentNavigationUnderlap() {
    guard let navigationController else { return }
    let bar = navigationController.navigationBar
    bar.isTranslucent = true
    if #available(iOS 26.0, *) {
      scrollView.topEdgeEffect.isHidden = true
    }
    navigationController.view.setNeedsLayout()
    navigationController.view.layoutIfNeeded()
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // Restore the Examples app Settings-style opaque bar when leaving this page.
    guard isMovingFromParent || isBeingDismissed else { return }
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundEffect = nil
    appearance.backgroundColor = .systemBackground
    appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
    let bar = navigationController?.navigationBar
    bar?.standardAppearance = appearance
    bar?.scrollEdgeAppearance = appearance
    bar?.compactAppearance = appearance
    bar?.compactScrollEdgeAppearance = appearance
    bar?.isTranslucent = false
    bar?.tintColor = .systemBlue
  }

  func addIntro(title: String, body: String) {
    let intro = UIStackView()
    intro.axis = .vertical
    intro.spacing = 8
    intro.isLayoutMarginsRelativeArrangement = true
    intro.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
    intro.addArrangedSubview(FKNavigationBarScrollExampleUI.headline(title))
    intro.addArrangedSubview(FKNavigationBarScrollExampleUI.caption(body))
    contentStack.addArrangedSubview(intro)
  }

  func addActions(_ buttons: [UIButton]) {
    actionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    buttons.forEach { actionsStack.addArrangedSubview($0) }
    if actionsStack.superview == nil {
      let wrapper = UIView()
      wrapper.translatesAutoresizingMaskIntoConstraints = false
      actionsStack.translatesAutoresizingMaskIntoConstraints = false
      wrapper.addSubview(actionsStack)
      NSLayoutConstraint.activate([
        actionsStack.topAnchor.constraint(equalTo: wrapper.topAnchor),
        actionsStack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        actionsStack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
        actionsStack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -16),
      ])
      contentStack.addArrangedSubview(wrapper)
    }
  }

  func addFillerBlocks(count: Int = 16) {
    let wrapper = UIStackView()
    wrapper.axis = .vertical
    wrapper.spacing = 12
    wrapper.isLayoutMarginsRelativeArrangement = true
    wrapper.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    for index in 0..<count {
      wrapper.addArrangedSubview(FKNavigationBarScrollExampleUI.makeFillerBlock(index: index))
    }
    contentStack.addArrangedSubview(wrapper)
  }

  func updateStatus(from engine: FKNavigationBarScrollEngine) {
    statusLabel.text = FKNavigationBarScrollExampleUI.formatProgress(engine)
  }

  /// Installs the scroll-associated engine with common hero endpoints and status wiring.
  @discardableResult
  func installDefaultEngine(
    endOffset: CGFloat? = nil,
    configure: ((FKNavigationBarScrollEngine) -> Void)? = nil
  ) -> FKNavigationBarScrollEngine {
    let engine = scrollView.fk_navigationBarScrollEngine
    var configuration = FKNavigationBarScrollConfiguration.default
    configuration.endOffset = endOffset ?? heroHeight
    configuration.usesAdjustedContentOffset = false
    engine.configuration = configuration
    engine.bind(viewController: self)
    engine.fromAppearance = .transparent(
      tint: .white,
      titleColor: .white,
      titleAlpha: 0,
      statusBarStyle: .lightContent
    )
    engine.toAppearance = .solid(
      backgroundColor: .systemBackground,
      titleColor: .label,
      tintColor: .label,
      titleAlpha: 1,
      shadowAlpha: 1,
      statusBarStyle: .darkContent
    )
    engine.onProgressChange = { [weak self, weak engine] _ in
      guard let self, let engine else { return }
      self.cachedStatusBarStyle = engine.resolvedStatusBarStyle
      self.updateStatus(from: engine)
    }
    configure?(engine)
    engine.reload()
    cachedStatusBarStyle = engine.resolvedStatusBarStyle
    updateStatus(from: engine)
    return engine
  }
}
