import UIKit

enum FKTimelineTimestampFormatter {
  static func string(for item: FKFlowStepItem, style: FKTimelineTimestampStyle) -> String? {
    switch style {
    case .hidden:
      return nil
    case .custom:
      return item.formattedTimestamp
    case .relative:
      guard let date = item.timestamp else { return item.formattedTimestamp }
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .abbreviated
      return formatter.localizedString(for: date, relativeTo: Date())
    case .absolute:
      if let formatted = item.formattedTimestamp { return formatted }
      guard let date = item.timestamp else { return nil }
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .short
      return formatter.string(from: date)
    }
  }
}
