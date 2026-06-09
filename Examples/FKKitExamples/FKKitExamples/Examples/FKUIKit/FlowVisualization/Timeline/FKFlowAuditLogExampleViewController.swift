import FKUIKit
import UIKit

/// Grouped ``FKTimelineSection`` rows with caption expansion.
final class FKFlowAuditLogExampleViewController: FKFlowVisualizationScrollViewController {

  private let timeline: FKTimeline = {
    var config = FKTimelinePresets.auditLog()
    config.interaction.allowsExpansion = true
    return FKTimeline(configuration: config)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Audit log"

    timeline.sections = FKFlowVisualizationExampleSupport.auditSections()

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: "Security events")
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "Sections replace flat `items`. Tap a row with a caption to expand details (`allowsExpansion`). Rounded-square nodes from the audit preset."
    ))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedTimeline(timeline, minHeight: 360))
    contentStack.addArrangedSubview(box)
  }
}
