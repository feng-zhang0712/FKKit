import Foundation

/// Content block for ``FKCellRegulatoryCell`` right column (D-15).
public enum FKCellRegulatoryBlock: Sendable, Equatable {
  case text(String)
  case image(FKCellImageContent)
  case spacer(height: CGFloat)
}
