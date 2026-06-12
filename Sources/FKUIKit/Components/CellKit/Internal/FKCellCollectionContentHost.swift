import UIKit

/// Embeds ``FKCellStandardRowLayout`` in any container (table or collection content views).
@MainActor
final class FKCellCollectionContentHost {
  let layout = FKCellStandardRowLayout()

  func install(in contentView: UIView) {
    layout.install(in: contentView)
  }

  func resetForReuse() {
    layout.resetForReuse()
  }
}
