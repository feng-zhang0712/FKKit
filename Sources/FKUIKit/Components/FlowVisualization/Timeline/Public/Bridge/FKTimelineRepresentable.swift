#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKTimeline``.
public struct FKTimelineRepresentable: UIViewRepresentable {
  public var items: [FKFlowStepItem]
  public var sections: [FKTimelineSection]?
  public var configuration: FKTimelineConfiguration
  public var onItemSelected: ((Int) -> Void)?

  public init(
    items: [FKFlowStepItem],
    sections: [FKTimelineSection]? = nil,
    configuration: FKTimelineConfiguration = FKTimelineDefaults.configuration,
    onItemSelected: ((Int) -> Void)? = nil
  ) {
    self.items = items
    self.sections = sections
    self.configuration = configuration
    self.onItemSelected = onItemSelected
  }

  public func makeUIView(context: Context) -> FKTimeline {
    let timeline = FKTimeline(configuration: configuration, items: items)
    timeline.sections = sections ?? []
    timeline.onItemSelected = { index, _ in
      onItemSelected?(index)
    }
    return timeline
  }

  public func updateUIView(_ uiView: FKTimeline, context: Context) {
    if uiView.configuration != configuration {
      uiView.configuration = configuration
    }
    if let sections, !sections.isEmpty {
      if uiView.sections != sections {
        uiView.sections = sections
      }
    } else if uiView.items != items {
      uiView.setItems(items, animated: false)
    }
    uiView.onItemSelected = { index, _ in
      onItemSelected?(index)
    }
  }
}
#endif
