import FKUIKit
import UIKit

/// Demonstrates static stickyInset and dynamic stickyInsetProvider.
///
/// Chrome **overlays** the scroll view. A top spacer keeps content readable; the provider
/// returns the chrome height so the stuck strip pins flush under the chrome (no double inset).
final class FKStickyInsetProviderExampleViewController: UIViewController {
  private let chromeView = UIView()
  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let topSpacer = UIView()
  private let statusLabel = FKStickyExampleUI.statusLabel()
  private let strip = FKStickyExampleUI.makeStrip(title: "Under chrome", backgroundColor: .systemOrange)
  private var chromeHeight: CGFloat = 0
  private var chromeHeightConstraint: NSLayoutConstraint?
  private var topSpacerHeightConstraint: NSLayoutConstraint?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Inset & Provider"
    view.backgroundColor = .systemGroupedBackground

    chromeView.backgroundColor = .systemGray5
    chromeView.translatesAutoresizingMaskIntoConstraints = false
    chromeView.isHidden = true
    let chromeLabel = UILabel()
    chromeLabel.text = "Simulated nav chrome"
    chromeLabel.font = .preferredFont(forTextStyle: .subheadline)
    chromeLabel.translatesAutoresizingMaskIntoConstraints = false
    chromeView.addSubview(chromeLabel)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    scrollView.contentInsetAdjustmentBehavior = .never
    contentStack.axis = .vertical
    contentStack.alignment = .fill
    contentStack.spacing = 12
    contentStack.translatesAutoresizingMaskIntoConstraints = false

    topSpacer.translatesAutoresizingMaskIntoConstraints = false
    let spacerHeight = topSpacer.heightAnchor.constraint(equalToConstant: 0)
    topSpacerHeightConstraint = spacerHeight
    spacerHeight.isActive = true

    // Scroll fills under the nav; chrome overlays it. Provider == chrome height → flush pin.
    view.addSubview(scrollView)
    view.addSubview(chromeView)
    view.addSubview(statusLabel)
    scrollView.addSubview(contentStack)

    statusLabel.translatesAutoresizingMaskIntoConstraints = false

    let height = chromeView.heightAnchor.constraint(equalToConstant: 0)
    chromeHeightConstraint = height
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      chromeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      chromeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      chromeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      height,
      chromeLabel.centerXAnchor.constraint(equalTo: chromeView.centerXAnchor),
      chromeLabel.centerYAnchor.constraint(equalTo: chromeView.centerYAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),

      statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])

    contentStack.addArrangedSubview(topSpacer)
    contentStack.addArrangedSubview(FKStickyExampleUI.headline("stickyInset + stickyInsetProvider"))
    contentStack.addArrangedSubview(
      FKStickyExampleUI.caption(
        "Chrome overlays the scroll view. Spacer clears content under chrome; provider returns the same height so the stuck strip sits flush under chrome."
      )
    )
    contentStack.addArrangedSubview(strip)
    strip.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true

    let actions = UIStackView(arrangedSubviews: [
      FKStickyExampleUI.makeButton("Chrome 0 pt") { [weak self] in self?.setChromeHeight(0) },
      FKStickyExampleUI.makeButton("Chrome 44 pt (provider)") { [weak self] in self?.setChromeHeight(44) },
      FKStickyExampleUI.makeButton("Chrome 88 pt (provider)") { [weak self] in self?.setChromeHeight(88) },
      FKStickyExampleUI.makeButton("Static stickyInset=24") { [weak self] in self?.useStaticInset(24) },
    ])
    actions.axis = .vertical
    actions.spacing = 8
    contentStack.addArrangedSubview(actions)

    for index in 0..<16 {
      contentStack.addArrangedSubview(FKStickyExampleUI.makeFillerBlock(index: index))
    }

    let engine = scrollView.fk_stickyEngine
    engine.stickyInsetProvider = { [weak self] in self?.chromeHeight ?? 0 }
    engine.addTarget(id: "under-chrome", view: strip) { [weak self] progress in
      guard let self else { return }
      self.statusLabel.text =
        "inset=\(Int(self.chromeHeight)) → \(progress.state.rawValue) p=\(String(format: "%.2f", progress.value))"
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    scrollView.fk_reloadStickyLayout()
  }

  private func setChromeHeight(_ height: CGFloat) {
    chromeHeight = height
    chromeHeightConstraint?.constant = height
    topSpacerHeightConstraint?.constant = height
    chromeView.isHidden = height <= 0
    scrollView.fk_stickyEngine.stickyInsetProvider = { [weak self] in self?.chromeHeight ?? 0 }
    var configuration = scrollView.fk_stickyEngine.configuration
    configuration.stickyInset = 0
    scrollView.fk_stickyEngine.configuration = configuration
    view.layoutIfNeeded()
    scrollView.fk_reloadStickyLayout()
    statusLabel.text = "Provider chromeHeight=\(Int(height))"
  }

  private func useStaticInset(_ inset: CGFloat) {
    chromeHeight = 0
    chromeHeightConstraint?.constant = 0
    topSpacerHeightConstraint?.constant = 0
    chromeView.isHidden = true
    scrollView.fk_stickyEngine.stickyInsetProvider = nil
    var configuration = scrollView.fk_stickyEngine.configuration
    configuration.stickyInset = inset
    scrollView.fk_stickyEngine.configuration = configuration
    view.layoutIfNeeded()
    scrollView.fk_reloadStickyLayout()
    statusLabel.text = "Static stickyInset=\(Int(inset)), provider=nil"
  }
}
