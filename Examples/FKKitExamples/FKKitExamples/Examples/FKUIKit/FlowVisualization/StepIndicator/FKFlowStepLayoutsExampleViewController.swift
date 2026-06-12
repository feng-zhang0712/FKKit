import FKUIKit
import UIKit

/// Side-by-side comparison of all ``FKStepIndicatorLayout`` variants.
final class FKFlowStepLayoutsExampleViewController: FKFlowVisualizationScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Layouts"

    let items = FKFlowVisualizationExampleSupport.checkoutItems()
    addLayoutSection(
      title: "Top labels (default)",
      caption: "`.horizontalTopLabels` — rail above titles.",
      layout: .horizontalTopLabels,
      items: items,
      currentIndex: 1
    )
    addLayoutSection(
      title: "Bottom labels",
      caption: "`.horizontalBottomLabels` — titles above nodes.",
      layout: .horizontalBottomLabels,
      items: items,
      currentIndex: 1
    )
    addLayoutSection(
      title: "Inline labels",
      caption: "`.horizontalInline` — best for 2–3 short steps.",
      layout: .horizontalInline,
      items: Array(items.prefix(3)),
      currentIndex: 1,
      minHeight: 108
    )
    addLayoutSection(
      title: "Compact dots",
      caption: "`.compactDots` — smaller nodes for dense headers.",
      layout: .compactDots,
      items: items,
      currentIndex: 2,
      compact: true
    )
  }

  private func addLayoutSection(
    title: String,
    caption: String,
    layout: FKStepIndicatorLayout,
    items: [FKFlowStepItem],
    currentIndex: Int,
    compact: Bool = false,
    minHeight: CGFloat? = nil
  ) {
    var config = FKStepIndicatorConfiguration()
    config.layout.layout = layout
    if compact {
      config.appearance.density = .compact
      config.appearance.nodeSize = .small
      config.layout.titleNumberOfLines = 1
    }
    let indicator = FKStepIndicator(configuration: config, items: items, currentStepIndex: currentIndex)

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: title)
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(caption))
    box.addArrangedSubview(
      FKFlowVisualizationExampleSupport.embedStepIndicator(
        indicator,
        minHeight: minHeight ?? (compact ? 72 : 88)
      )
    )
    contentStack.addArrangedSubview(box)
  }
}
