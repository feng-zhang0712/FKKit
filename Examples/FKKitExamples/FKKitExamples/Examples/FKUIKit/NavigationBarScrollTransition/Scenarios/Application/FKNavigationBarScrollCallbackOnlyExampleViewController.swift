import FKUIKit
import UIKit

/// Host paints chrome from callbacks without automatic appearance writes.
final class FKNavigationBarScrollCallbackOnlyExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Callback Only" }
  private let previewLabel = FKNavigationBarScrollExampleUI.caption("Waiting for onAppearanceChange…")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Manual Apply"

    addIntro(
      title: "Callback-only mode",
      body: "appliesAppearanceAutomatically = false. The engine still computes progress and resolvedAppearance; the host applies chrome (here: a preview label + navigationBar.tintColor only)."
    )

    let previewWrap = UIView()
    previewWrap.translatesAutoresizingMaskIntoConstraints = false
    previewLabel.translatesAutoresizingMaskIntoConstraints = false
    previewLabel.numberOfLines = 0
    previewWrap.addSubview(previewLabel)
    NSLayoutConstraint.activate([
      previewLabel.topAnchor.constraint(equalTo: previewWrap.topAnchor, constant: 8),
      previewLabel.bottomAnchor.constraint(equalTo: previewWrap.bottomAnchor, constant: -8),
      previewLabel.leadingAnchor.constraint(equalTo: previewWrap.leadingAnchor, constant: 16),
      previewLabel.trailingAnchor.constraint(equalTo: previewWrap.trailingAnchor, constant: -16),
    ])
    contentStack.addArrangedSubview(previewWrap)
    addFillerBlocks()

    _ = installDefaultEngine { [weak self] engine in
      var configuration = engine.configuration
      configuration.appliesAppearanceAutomatically = false
      engine.configuration = configuration
      engine.onAppearanceChange = { appearance, progress in
        self?.previewLabel.text = String(
          format: "onAppearanceChange p=%.2f  bgα=%.2f titleα=%.2f tint=%@",
          progress,
          appearance.backgroundAlpha,
          appearance.titleAlpha,
          appearance.tintColor == nil ? "nil" : "set"
        )
        if let tint = appearance.tintColor {
          self?.navigationController?.navigationBar.tintColor = tint
        }
        // Keep a minimal transparent/solid item appearance so the demo stays readable.
        let bar = UINavigationBarAppearance()
        let base = appearance.backgroundColor ?? .systemBackground
        if appearance.backgroundAlpha < 0.05 {
          bar.configureWithTransparentBackground()
          bar.backgroundEffect = nil
          bar.backgroundColor = .clear
        } else if appearance.backgroundAlpha >= 0.99 {
          bar.configureWithOpaqueBackground()
          bar.backgroundEffect = nil
          bar.backgroundColor = base
        } else {
          bar.configureWithTransparentBackground()
          bar.backgroundEffect = nil
          bar.backgroundColor = base.withAlphaComponent(appearance.backgroundAlpha)
        }
        if let titleColor = appearance.titleColor {
          bar.titleTextAttributes = [
            .foregroundColor: titleColor.withAlphaComponent(appearance.titleAlpha)
          ]
        }
        self?.navigationItem.standardAppearance = bar
        self?.navigationItem.scrollEdgeAppearance = bar
        self?.navigationController?.navigationBar.isTranslucent = appearance.backgroundAlpha < 0.99
      }
    }
  }
}
