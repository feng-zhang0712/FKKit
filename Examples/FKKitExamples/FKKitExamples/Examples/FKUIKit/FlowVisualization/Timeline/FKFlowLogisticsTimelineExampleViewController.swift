import FKUIKit
import UIKit

/// Shipment tracking with logistics preset, tail line, and scroll-to-row.
final class FKFlowLogisticsTimelineExampleViewController: FKFlowVisualizationScrollViewController {

  private let timeline = FKTimeline(configuration: FKTimelinePresets.logistics())

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Logistics"

    timeline.items = FKFlowVisualizationExampleSupport.logisticsItems()

    let scrollButton = FKFlowVisualizationExampleSupport.primaryButton(title: "Scroll to “In transit”", action: UIAction { [weak self] _ in
      self?.timeline.scrollToStep(id: "transit", animated: true)
    })

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: "Delivery timeline")
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "`FKTimelinePresets.logistics()` with absolute timestamps, current-step emphasis, and a dotted tail for in-progress delivery."
    ))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedTimeline(timeline, minHeight: 200))
    box.addArrangedSubview(scrollButton)
    contentStack.addArrangedSubview(box)
  }
}
