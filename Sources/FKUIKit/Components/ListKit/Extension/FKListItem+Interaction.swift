import Foundation

extension FKListItem {
  /// Resolved selectability from metadata and preset row flags.
  var resolvedIsSelectable: Bool {
    if metadata?.isSelectable == false { return false }
    switch kind {
    case .preset(let preset):
      switch preset {
      case .text(let row): return row.isSelectable && row.isEnabled
      case .subtitle(let row): return row.isSelectable && row.isEnabled
      case .icon(let row): return row.isSelectable && row.isEnabled
      case .switch: return false
      case .checkbox: return false
      case .disclosure(let row): return row.isSelectable && row.isEnabled
      case .customValue(let row): return row.isSelectable && row.isEnabled
      }
    case .custom:
      return metadata?.isSelectable ?? true
    }
  }
}
