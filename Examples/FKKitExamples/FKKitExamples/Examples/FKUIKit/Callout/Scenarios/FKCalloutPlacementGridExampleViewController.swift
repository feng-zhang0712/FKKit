import UIKit
import FKUIKit

/// Demonstrates every FKCalloutPlacement and custom beak offsets.
final class FKCalloutPlacementGridExampleViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Placement anchor")

  private let placements: [(String, FKCalloutPlacement)] = [
    ("Top", .top),
    ("Top leading", .topLeading),
    ("Top trailing", .topTrailing),
    ("Bottom", .bottom),
    ("Bottom leading", .bottomLeading),
    ("Bottom trailing", .bottomTrailing),
    ("Leading", .leading),
    ("Leading top", .leadingTop),
    ("Leading bottom", .leadingBottom),
    ("Trailing", .trailing),
    ("Trailing top", .trailingTop),
    ("Trailing bottom", .trailingBottom),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Placements & beak"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "Cycle through explicit placements or use `.automatic` in Beak offset.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor)
      )
    )

    var gridRows: [UIView] = []
    var buffer: [UIView] = []
    for (index, item) in placements.enumerated() {
      let button = FKCalloutExampleUI.button(item.0) { [weak self] in
        self?.present(placement: item.1)
      }
      buffer.append(button)
      if buffer.count == 2 || index == placements.count - 1 {
        gridRows.append(FKCalloutExampleUI.row(buffer))
        buffer = []
      }
    }

    let grid = UIStackView(arrangedSubviews: gridRows)
    grid.axis = .vertical
    grid.spacing = 8

    let extra = UIStackView()
    extra.axis = .vertical
    extra.spacing = 8
    extra.addArrangedSubview(
      FKCalloutExampleUI.button("Automatic placement") { [weak self] in
        self?.present(placement: .automatic)
      }
    )
    extra.addArrangedSubview(
      FKCalloutExampleUI.button("Beak fraction 0.12 (bubble edge)") { [weak self] in
        self?.present(placement: .bottom, beakOffset: .fraction(0.12, reference: .bubbleEdge))
      }
    )
    extra.addArrangedSubview(
      FKCalloutExampleUI.button("Beak fixed 72pt (bubble edge)") { [weak self] in
        self?.present(placement: .bottom, beakOffset: .fixed(72, reference: .bubbleEdge))
      }
    )
    extra.addArrangedSubview(
      FKCalloutExampleUI.button("Beak anchor fraction 0.5") { [weak self] in
        self?.present(placement: .bottomLeading, beakOffset: .fraction(0.5, reference: .anchor))
      }
    )
    extra.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss") { FKCallout.dismissActive() }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "12 placements",
        description: "FKCalloutPlacement covers start/center/end on each side.",
        body: grid
      )
    )
    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Beak offset",
        description: "automatic uses corners on compound placements; fraction/fixed support bubbleEdge and anchor references.",
        body: extra
      )
    )
  }

  private func present(placement: FKCalloutPlacement, beakOffset: FKCalloutBeakOffset = .automatic) {
    var config = FKCalloutConfiguration.tooltipDefault(placement: placement)
    config.maxWidth = 300
    config.beakOffset = beakOffset
    config.autoDismissDuration = nil
    config.tapOutsideToDismiss = true
    config.passesThroughOutsideTouches = false
    FKCallout.show(
      content: .message("Placement: \(placement)"),
      anchoredTo: anchor,
      configuration: config
    )
    log("FKCallout.show · .\(placement)")
  }
}
