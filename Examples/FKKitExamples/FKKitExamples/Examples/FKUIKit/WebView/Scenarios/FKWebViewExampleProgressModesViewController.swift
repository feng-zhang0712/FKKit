import FKUIKit
import UIKit

/// Switches ``FKWebProgressPresentation`` modes on a live ``FKWebView``.
final class FKWebViewExampleProgressModesViewController: UIViewController {
  private let webView = FKWebView()
  private let modeControl = UISegmentedControl(items: ["Linear", "Safe top", "Indeterminate", "None"])
  private let hintLabel = FKWebViewExampleSupport.makeCaptionLabel(
    "Each segment reloads a 2s delayed page. Watch the top edge (or below the nav bar) for the thin progress strip."
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Progress modes"
    view.backgroundColor = .systemBackground

    modeControl.selectedSegmentIndex = 0
    modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
    modeControl.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hintLabel)
    view.addSubview(modeControl)
    view.addSubview(container)

    NSLayoutConstraint.activate([
      hintLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      hintLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      hintLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      modeControl.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 8),
      modeControl.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      modeControl.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      container.topAnchor.constraint(equalTo: modeControl.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    modeChanged()
  }

  @objc private func modeChanged() {
    var configuration = webView.configuration
    configuration.presentation.progress.completeHideDelay = 1.0
    switch modeControl.selectedSegmentIndex {
    case 1:
      configuration.presentation.progress.presentation = .linearBarTopSafeArea
    case 2:
      configuration.presentation.progress.presentation = .indeterminateUntilFirstPaint
    case 3:
      configuration.presentation.progress.presentation = .none
    default:
      configuration.presentation.progress.presentation = .linearBar
    }
    webView.configuration = configuration
    webView.load(FKWebViewExampleURLs.slowHTTPS)
  }
}
