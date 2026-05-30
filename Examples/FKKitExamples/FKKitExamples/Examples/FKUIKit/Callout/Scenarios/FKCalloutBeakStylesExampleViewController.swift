import UIKit
import FKUIKit

/// Demonstrates ``FKCalloutBeakStyle`` presets and a custom beak view.
final class FKCalloutBeakStylesExampleViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Beak anchor")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Beak styles"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "Each row applies a different beak shape on a bottom popover. Beak offset demos live in Placements & beak.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor)
      )
    )

    let styles = UIStackView()
    styles.axis = .vertical
    styles.spacing = 8
    styles.addArrangedSubview(FKCalloutExampleUI.button("Isosceles (default)") { [weak self] in
      self?.presentStyle(.isosceles, label: "isosceles")
    })
    styles.addArrangedSubview(FKCalloutExampleUI.button("Equilateral") { [weak self] in
      self?.presentStyle(.equilateral, label: "equilateral")
    })
    styles.addArrangedSubview(FKCalloutExampleUI.button("Right angle · leading corner") { [weak self] in
      self?.presentStyle(.rightAngle(corner: .leading, apexAlongBase: 1), label: "rightAngle.leading")
    })
    styles.addArrangedSubview(FKCalloutExampleUI.button("Right angle · trailing corner") { [weak self] in
      self?.presentStyle(.rightAngle(corner: .trailing, apexAlongBase: 0), label: "rightAngle.trailing")
    })
    styles.addArrangedSubview(FKCalloutExampleUI.button("Polygon (wide tip)") { [weak self] in
      self?.presentStyle(
        .polygon(vertices: [
          CGPoint(x: 0.15, y: 0),
          CGPoint(x: 0.85, y: 0),
          CGPoint(x: 0.65, y: 1),
          CGPoint(x: 0.35, y: 1),
        ]),
        label: "polygon"
      )
    })
    styles.addArrangedSubview(FKCalloutExampleUI.button("Custom UIView beak") { [weak self] in
      self?.presentCustomBeak()
    })
    styles.addArrangedSubview(FKCalloutExampleUI.button("Dismiss") { FKCallout.dismissActive() })

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "FKCalloutBeakStyle",
        description: "Configure via FKCalloutAppearance.beakStyle, or replace the path beak with FKCalloutBuilder.customBeakViewProvider.",
        body: styles
      )
    )
  }

  private func presentStyle(_ style: FKCalloutBeakStyle, label: String) {
    var config = baseConfiguration()
    config.appearance.beakStyle = style
    if case .equilateral = style {
      config.appearance.beakWidth = 20
    }
    show(config: config, message: "Beak style: \(label)")
  }

  private func presentCustomBeak() {
    var config = baseConfiguration()
    config.appearance.beakWidth = 28
    config.appearance.beakHeight = 18
    var builder = FKCalloutBuilder(
      content: .message("Custom beak UIView"),
      configuration: config
    )
    builder.anchorView = anchor
    builder.customBeakViewProvider = {
      let view = UIImageView(image: UIImage(systemName: "arrowtriangle.down.fill"))
      view.tintColor = .systemPurple
      view.contentMode = .scaleAspectFit
      return view
    }
    FKCallout.show(builder: builder)
    log("FKCalloutBuilder.customBeakViewProvider")
  }

  private func baseConfiguration() -> FKCalloutConfiguration {
    var config = FKCalloutConfiguration.popoverDefault(placement: .bottom)
    config.anchorAlignment = .center
    config.autoDismissDuration = nil
    config.tapOutsideToDismiss = true
    config.passesThroughOutsideTouches = false
    config.appearance.beakWidth = 18
    config.appearance.beakHeight = 10
    config.appearance.beakCornerInset = 14
    return config
  }

  private func show(config: FKCalloutConfiguration, message: String) {
    FKCallout.show(content: .message(message), anchoredTo: anchor, configuration: config)
    log("FKCallout.show · \(message)")
  }
}
