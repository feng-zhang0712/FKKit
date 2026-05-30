import UIKit

extension FKCalloutPlacement {
  enum BeakEdge {
    case top
    case bottom
    case leading
    case trailing
  }

  enum BeakAlignment {
    case center
    case leading
    case trailing
  }

  var beakEdge: BeakEdge {
    switch self {
    case .automatic, .top, .topLeading, .topTrailing:
      return .bottom
    case .bottom, .bottomLeading, .bottomTrailing:
      return .top
    case .leading, .leadingTop, .leadingBottom:
      return .trailing
    case .trailing, .trailingTop, .trailingBottom:
      return .leading
    }
  }

  var preferredBeakAlignment: BeakAlignment {
    switch self {
    case .automatic, .top, .bottom, .leading, .trailing:
      return .center
    case .topLeading, .bottomLeading, .leadingTop, .trailingTop:
      return .leading
    case .topTrailing, .bottomTrailing, .leadingBottom, .trailingBottom:
      return .trailing
    }
  }

  /// Suggested opposite placement used when flipping does not fit.
  var flipped: FKCalloutPlacement {
    switch self {
    case .automatic: return .automatic
    case .top: return .bottom
    case .topLeading: return .bottomLeading
    case .topTrailing: return .bottomTrailing
    case .bottom: return .top
    case .bottomLeading: return .topLeading
    case .bottomTrailing: return .topTrailing
    case .leading: return .trailing
    case .leadingTop: return .trailingTop
    case .leadingBottom: return .trailingBottom
    case .trailing: return .leading
    case .trailingTop: return .leadingTop
    case .trailingBottom: return .leadingBottom
    }
  }
}
