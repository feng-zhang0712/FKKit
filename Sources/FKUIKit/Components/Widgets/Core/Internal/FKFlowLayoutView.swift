import UIKit

/// Flow-wrap layout container for horizontally arranged subviews (used by ``FKChipGroup``).
final class FKFlowLayoutView: UIView {
  var itemSpacing: CGFloat = 8 {
    didSet { setNeedsLayout() }
  }

  var lineSpacing: CGFloat = 8 {
    didSet { setNeedsLayout() }
  }

  var contentInsets: UIEdgeInsets = .zero {
    didSet { setNeedsLayout() }
  }

  private(set) var laidOutSize: CGSize = .zero

  /// When `false`, items stay on a single row (may clip if wider than bounds).
  var allowsWrap: Bool = true {
    didSet { setNeedsLayout() }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let layoutMaxWidth = allowsWrap ? bounds.width : max(bounds.width, .greatestFiniteMagnitude)
    guard layoutMaxWidth > 0 || !allowsWrap else { return }
    applyLayout(maxWidth: layoutMaxWidth)
  }

  override var semanticContentAttribute: UISemanticContentAttribute {
    didSet {
      guard oldValue != semanticContentAttribute else { return }
      setNeedsLayout()
    }
  }

  override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: laidOutSize.height)
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let width = size.width > 0 && size.width != UIView.noIntrinsicMetric ? size.width : 0
    guard width > 0 else {
      return CGSize(width: UIView.noIntrinsicMetric, height: laidOutSize.height)
    }
    return measureLayout(maxWidth: width)
  }

  /// Measures and applies frames for the current subviews.
  @discardableResult
  func applyLayout(maxWidth: CGFloat) -> CGSize {
    let size = measureLayout(maxWidth: maxWidth)
    laidOutSize = size
    invalidateIntrinsicContentSize()
    return size
  }

  /// Returns the laid-out size and assigns child frames (used for intrinsic sizing before ``layoutSubviews``).
  @discardableResult
  func measureLayout(maxWidth: CGFloat) -> CGSize {
    FKFlowLayoutEngine.layout(
      subviews: subviews.filter { !$0.isHidden },
      in: maxWidth,
      itemSpacing: itemSpacing,
      lineSpacing: lineSpacing,
      insets: contentInsets,
      allowsWrap: allowsWrap,
      layoutDirection: effectiveUserInterfaceLayoutDirection
    )
  }
}

enum FKFlowLayoutEngine {
  @discardableResult
  static func layout(
    subviews: [UIView],
    in maxWidth: CGFloat,
    itemSpacing: CGFloat,
    lineSpacing: CGFloat,
    insets: UIEdgeInsets,
    allowsWrap: Bool = true,
    layoutDirection: UIUserInterfaceLayoutDirection = .leftToRight
  ) -> CGSize {
    if allowsWrap {
      guard maxWidth > 0 else { return .zero }
    }

    let isRTL = layoutDirection == .rightToLeft
    let contentWidth = allowsWrap
      ? max(0, maxWidth - insets.left - insets.right)
      : .greatestFiniteMagnitude
    let orderedSubviews = isRTL ? subviews.reversed() : subviews
    var y = insets.top
    var rowHeight: CGFloat = 0
    var cursorX = isRTL ? maxWidth - insets.right : insets.left
    var rowHasItems = false
    var contentExtent: CGFloat = 0

    for view in orderedSubviews {
      let size = view.systemLayoutSizeFitting(
        CGSize(width: contentWidth, height: UIView.layoutFittingCompressedSize.height),
        withHorizontalFittingPriority: .fittingSizeLevel,
        verticalFittingPriority: .fittingSizeLevel
      )
      let width = max(view.intrinsicContentSize.width, size.width)
      let height = max(view.intrinsicContentSize.height, size.height)

      if allowsWrap {
        let wouldOverflow: Bool
        if isRTL {
          wouldOverflow = rowHasItems && cursorX - width < insets.left
        } else {
          wouldOverflow = rowHasItems && cursorX + width > insets.left + contentWidth
        }
        if wouldOverflow {
          cursorX = isRTL ? maxWidth - insets.right : insets.left
          y += rowHeight + lineSpacing
          rowHeight = 0
          rowHasItems = false
        }
      }

      let originX: CGFloat
      if isRTL {
        cursorX -= width
        originX = cursorX
        cursorX -= itemSpacing
      } else {
        originX = cursorX
        cursorX += width + itemSpacing
      }

      view.frame = CGRect(x: originX, y: y, width: width, height: height)
      rowHeight = max(rowHeight, height)
      rowHasItems = true
      contentExtent += width + (contentExtent > 0 ? itemSpacing : 0)
    }

    let totalHeight = subviews.isEmpty ? 0 : y + rowHeight + insets.bottom
    let totalWidth: CGFloat
    if allowsWrap {
      totalWidth = maxWidth
    } else {
      totalWidth = subviews.isEmpty ? 0 : contentExtent + insets.left + insets.right
    }
    return CGSize(width: totalWidth, height: totalHeight)
  }
}
