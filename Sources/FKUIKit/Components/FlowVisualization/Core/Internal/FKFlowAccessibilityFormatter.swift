import Foundation

enum FKFlowAccessibilityFormatter {
  static func stepLabel(
    index: Int,
    count: Int,
    item: FKFlowStepItem,
    configuration: FKFlowAccessibilityConfiguration
  ) -> String {
    let title = fullText(primary: item.title, secondary: item.subtitle)
    return interpolate(
      configuration.stepLabelFormat,
      replacements: [
        "index": "\(index + 1)",
        "count": "\(count)",
        "title": title,
        "state": localizedState(item.state),
      ]
    )
  }

  static func timelineLabel(
    item: FKFlowStepItem,
    timestamp: String?,
    configuration: FKFlowAccessibilityConfiguration
  ) -> String {
    let title = fullText(primary: item.title, secondary: item.subtitle)
    let caption = item.caption ?? ""
    return interpolate(
      configuration.timelineLabelFormat,
      replacements: [
        "title": title,
        "timestamp": timestamp ?? "",
        "caption": caption,
        "state": localizedState(item.state),
      ]
    )
  }

  static func localizedState(_ state: FKFlowStepState) -> String {
    switch state {
    case .completed: return "Completed"
    case .current: return "Current step"
    case .upcoming: return "Upcoming"
    case .error: return "Error"
    case .skipped: return "Skipped"
    case .disabled: return "Disabled"
    }
  }

  private static func fullText(primary: String, secondary: String?) -> String {
    guard let secondary, !secondary.isEmpty else { return primary }
    return "\(primary), \(secondary)"
  }

  private static func interpolate(_ template: String, replacements: [String: String]) -> String {
    replacements.reduce(template) { result, pair in
      result.replacingOccurrences(of: "{\(pair.key)}", with: pair.value)
    }
  }
}
