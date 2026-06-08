import UIKit

/// Debug helper for comparing FKImageView subtree depth across integration profiles.
enum FKImageViewExampleHierarchy {
  /// Total descendant count excluding the root view itself.
  static func descendantCount(of view: UIView) -> Int {
    var count = 0
    func walk(_ node: UIView) {
      for child in node.subviews {
        count += 1
        walk(child)
      }
    }
    walk(view)
    return count
  }

  /// Visible descendant count (`isHidden == false` along the ancestor chain).
  static func visibleDescendantCount(of view: UIView) -> Int {
    var count = 0
    func walk(_ node: UIView, ancestorsVisible: Bool) {
      for child in node.subviews {
        let visible = ancestorsVisible && !child.isHidden && child.alpha > 0.01
        if visible { count += 1 }
        walk(child, ancestorsVisible: visible)
      }
    }
    walk(view, ancestorsVisible: !view.isHidden && view.alpha > 0.01)
    return count
  }

  /// Text tree for on-screen inspection (mirrors Xcode View Hierarchy from root down).
  static func treeDescription(for view: UIView, maxDepth: Int = 12) -> String {
    var lines: [String] = []
    appendNode(view, depth: 0, maxDepth: maxDepth, to: &lines)
    return lines.joined(separator: "\n")
  }

  private static func appendNode(_ view: UIView, depth: Int, maxDepth: Int, to lines: inout [String]) {
    let indent = String(repeating: "  ", count: depth)
    let flags = visibilityFlags(for: view)
    lines.append("\(indent)\(typeName(view))\(flags)")

    guard depth < maxDepth else {
      if !view.subviews.isEmpty {
        lines.append("\(indent)  …")
      }
      return
    }
    for child in view.subviews {
      appendNode(child, depth: depth + 1, maxDepth: maxDepth, to: &lines)
    }
  }

  private static func typeName(_ view: UIView) -> String {
    String(describing: type(of: view))
  }

  private static func visibilityFlags(for view: UIView) -> String {
    var parts: [String] = []
    if view.isHidden { parts.append("hidden") }
    if view.alpha < 0.99 { parts.append(String(format: "alpha=%.2f", view.alpha)) }
    guard !parts.isEmpty else { return "" }
    return " [\(parts.joined(separator: ", "))]"
  }
}
