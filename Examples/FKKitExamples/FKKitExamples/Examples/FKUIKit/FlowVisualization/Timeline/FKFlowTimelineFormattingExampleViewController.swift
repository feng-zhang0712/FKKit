import FKUIKit
import UIKit

/// Timestamp display modes and connector tail styles.
final class FKFlowTimelineFormattingExampleViewController: FKFlowVisualizationScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Formatting"

    let baseItem = FKFlowStepItem(
      id: "event",
      title: "Package scanned",
      subtitle: "Regional hub",
      caption: "Scan ID: SC-8821",
      timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date()),
      formattedTimestamp: "Mar 8, 10:00 AM",
      state: .current
    )

    addTimestampSection(style: .relative, title: "Relative", item: baseItem)
    addTimestampSection(style: .absolute, title: "Absolute", item: baseItem)
    addTimestampSection(style: .custom, title: "Custom", item: baseItem)
    addTimestampSection(style: .hidden, title: "Hidden", item: baseItem)

    addTailSection(style: .none, title: "Tail: none")
    addTailSection(style: .dotted, title: "Tail: dotted")
    addTailSection(style: .toFuture, title: "Tail: to future")
  }

  private func addTimestampSection(style: FKTimelineTimestampStyle, title: String, item: FKFlowStepItem) {
    var config = FKTimelineConfiguration()
    config.layout.timestampStyle = style
    config.layout.tailStyle = .none
    let timeline = FKTimeline(configuration: config, items: [item])

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: title)
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption("`.timestampStyle = .\(String(describing: style))`"))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedTimeline(timeline, minHeight: 100))
    contentStack.addArrangedSubview(box)
  }

  private func addTailSection(style: FKTimelineTailStyle, title: String) {
    var config = FKTimelineConfiguration()
    config.layout.tailStyle = style
    let timeline = FKTimeline(configuration: config, items: [
      FKFlowStepItem(id: "a", title: "Shipped", state: .completed),
      FKFlowStepItem(id: "b", title: "In transit", state: .current),
    ])

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: title)
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption("Connector below the last node when delivery is still in progress."))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedTimeline(timeline, minHeight: 140))
    contentStack.addArrangedSubview(box)
  }
}
