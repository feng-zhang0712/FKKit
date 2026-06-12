import FKUIKit
import UIKit

/// Explores FKThemeResolver color and scrim helpers.
final class FKThemeExampleResolverViewController: FKThemeExampleBaseViewController {

  private let scrimPreview = UIView()
  private let surfacePreview = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Resolver & scrim"

    scrimPreview.layer.cornerRadius = 12
    scrimPreview.translatesAutoresizingMaskIntoConstraints = false
    scrimPreview.heightAnchor.constraint(equalToConstant: 120).isActive = true

    surfacePreview.layer.cornerRadius = 12
    surfacePreview.translatesAutoresizingMaskIntoConstraints = false
    surfacePreview.heightAnchor.constraint(equalToConstant: 80).isActive = true

    updatePreviews()

    let previews = UIStackView(arrangedSubviews: [scrimPreview, surfacePreview])
    previews.axis = .vertical
    previews.spacing = 12

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "FKThemeResolver accessibility helpers",
        description: "Scrim and surface colors increase opacity when UIAccessibility.isReduceTransparencyEnabled is on.",
        content: previews
      )
    )

    let theme = FKThemeRegistry.current
    let resolved = FKThemeResolver.color(.primary, in: theme, traitCollection: traitCollection)
    stack.addArrangedSubview(
      FKThemeExampleSupport.colorSwatch(
        name: "Resolved primary for current trait",
        color: resolved
      )
    )

    stack.addArrangedSubview(
      FKThemeExampleSupport.bodyLabel("Use FKThemeColor.resolved(for:) or FKThemeResolver.color(_:in:traitCollection:) inside layoutSubviews and traitCollectionDidChange.")
    )
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updatePreviews()
  }

  private func updatePreviews() {
    let theme = FKThemeRegistry.current
    scrimPreview.backgroundColor = FKThemeResolver.scrimColor(in: theme, traitCollection: traitCollection)
    surfacePreview.backgroundColor = FKThemeResolver.surfaceColor(elevated: true, in: theme, traitCollection: traitCollection)

    configurePreviewLabel(in: scrimPreview, text: "Modal scrim preview", color: .white)
    configurePreviewLabel(
      in: surfacePreview,
      text: "Elevated surface preview",
      color: FKThemeResolver.color(.onSurface, in: theme, traitCollection: traitCollection)
    )
  }

  private func configurePreviewLabel(in container: UIView, text: String, color: UIColor) {
    let label = UILabel()
    label.text = text
    label.textColor = color
    label.font = .preferredFont(forTextStyle: .headline)
    label.translatesAutoresizingMaskIntoConstraints = false
    container.subviews.forEach { $0.removeFromSuperview() }
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])
  }
}
