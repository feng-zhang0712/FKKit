import FKUIKit
import UIKit

/// Selectable timeline rows with optional delegate gating.
final class FKFlowTimelineSelectionExampleViewController: FKFlowVisualizationScrollViewController, FKTimelineDelegate {

  private let timeline: FKTimeline = {
    var config = FKTimelineConfiguration()
    config.interaction.allowsSelection = true
    config.interaction.selectableStates = [.completed, .current]
    config.interaction.hapticOnSelect = true
    return FKTimeline(configuration: config)
  }()

  private let logLabel = FKFlowVisualizationExampleSupport.monospacedLogLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Selection"

    timeline.items = FKFlowVisualizationExampleSupport.logisticsItems()
    timeline.delegate = self
    timeline.onItemSelected = { [weak self] index, item in
      FKFlowVisualizationExampleSupport.appendLog("onItemSelected(\(index), \"\(item.title)\")", to: self?.logLabel ?? UILabel())
    }

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: "Tap a row")
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "Completed and current rows are selectable. The delegate blocks selection of the first row for demonstration."
    ))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedTimeline(timeline, minHeight: 300))
    box.addArrangedSubview(logLabel)
    contentStack.addArrangedSubview(box)
  }

  func timeline(_ timeline: FKTimeline, shouldSelectItemAt index: Int) -> Bool {
    index != 0
  }

  func timeline(_ timeline: FKTimeline, didSelectItemAt index: Int) {
    FKFlowVisualizationExampleSupport.appendLog("delegate didSelectItemAt(\(index))", to: logLabel)
  }
}
