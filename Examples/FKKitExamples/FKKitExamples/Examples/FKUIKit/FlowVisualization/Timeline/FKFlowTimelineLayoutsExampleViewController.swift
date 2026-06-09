import FKUIKit
import UIKit

/// Leading, trailing, and embedded timeline rails.
final class FKFlowTimelineLayoutsExampleViewController: FKFlowVisualizationScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Rail layouts"

    let items = Array(FKFlowVisualizationExampleSupport.logisticsItems().prefix(3))

    addSection(
      title: "Leading rail",
      caption: "`.verticalLeadingRail` — default LTR placement.",
      layout: .verticalLeadingRail
    ) { timeline in
      timeline.items = items
    }

    addSection(
      title: "Trailing rail",
      caption: "`.verticalTrailingRail` — rail on the trailing edge.",
      layout: .verticalTrailingRail
    ) { timeline in
      timeline.items = items
    }

    addSection(
      title: "Embedded in list",
      caption: "`.embeddedInList` — reduced padding for table cells.",
      layout: .embeddedInList
    ) { timeline in
      timeline.items = items
    }
  }

  private func addSection(
    title: String,
    caption: String,
    layout: FKTimelineLayout,
    configure: (FKTimeline) -> Void
  ) {
    var config = FKTimelineConfiguration()
    config.layout.layout = layout
    let timeline = FKTimeline(configuration: config)
    configure(timeline)

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: title)
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(caption))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedTimeline(timeline, minHeight: 220))
    contentStack.addArrangedSubview(box)
  }
}
