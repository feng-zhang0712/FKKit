import UIKit

public extension FKSheetPresentationConfiguration {
  public enum Layout {
    case bottomSheet(SheetConfiguration)
    case topSheet(SheetConfiguration)
    case center(CenterConfiguration)
    case anchor(FKAnchorConfiguration)
    case edge(UIRectEdge)
  }
}
