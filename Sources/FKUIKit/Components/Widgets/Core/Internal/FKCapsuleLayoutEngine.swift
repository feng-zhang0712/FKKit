import CoreGraphics
import UIKit

/// Shared capsule measurement for Chip, Tag, and related widgets.
enum FKCapsuleLayoutEngine {
  struct Input: Equatable {
    var title: String
    var font: UIFont
    var height: CGFloat
    var horizontalPadding: CGFloat
    var iconSpacing: CGFloat
    var leadingIconPointSize: CGFloat
    var hasLeadingIcon: Bool
    var showsRemoveButton: Bool
    var removeSymbolPointSize: CGFloat
    var removeHitSide: CGFloat
    var maxWidth: CGFloat?
  }

  struct Metrics: Equatable {
    var size: CGSize
    var cornerRadius: CGFloat
    var leadingIconFrame: CGRect?
    var titleFrame: CGRect
    /// Visual symbol frame for the remove glyph.
    var removeButtonFrame: CGRect?
    /// Expanded hit target for the remove control, confined to the trailing gutter (does not overlap ``titleFrame``).
    var removeHitAreaFrame: CGRect?
  }

  static func layout(_ input: Input) -> Metrics {
    let cornerRadius = input.height / 2
    let iconSide = input.hasLeadingIcon ? input.leadingIconPointSize : 0
    let removeVisualWidth = input.showsRemoveButton ? input.removeSymbolPointSize + 4 : 0
    let removeLayoutWidth = input.showsRemoveButton ? removeVisualWidth + input.iconSpacing : 0

    let maxTitleWidth: CGFloat
    if let cap = input.maxWidth {
      maxTitleWidth = max(
        0,
        cap - input.horizontalPadding * 2 - (input.hasLeadingIcon ? iconSide + input.iconSpacing : 0)
          - removeLayoutWidth
      )
    } else {
      maxTitleWidth = .greatestFiniteMagnitude
    }

    let titleSize = (input.title as NSString).boundingRect(
      with: CGSize(width: maxTitleWidth, height: input.height),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: input.font],
      context: nil
    ).size

    let contentWidth = input.horizontalPadding
      + (input.hasLeadingIcon ? iconSide + input.iconSpacing : 0)
      + ceil(titleSize.width)
      + removeLayoutWidth
      + input.horizontalPadding

    let width = min(input.maxWidth ?? contentWidth, max(input.height, contentWidth))
    let bounds = CGRect(origin: .zero, size: CGSize(width: width, height: input.height))

    var x = input.horizontalPadding
    var leadingIconFrame: CGRect?
    if input.hasLeadingIcon {
      let y = (input.height - iconSide) / 2
      leadingIconFrame = CGRect(x: x, y: y, width: iconSide, height: iconSide)
      x += iconSide + input.iconSpacing
    }

    let titleFrame = CGRect(
      x: x,
      y: 0,
      width: max(0, width - x - input.horizontalPadding - removeLayoutWidth),
      height: input.height
    )

    var removeButtonFrame: CGRect?
    var removeHitAreaFrame: CGRect?
    if input.showsRemoveButton {
      removeButtonFrame = CGRect(
        x: width - input.horizontalPadding - removeVisualWidth,
        y: (input.height - input.removeSymbolPointSize) / 2,
        width: removeVisualWidth,
        height: input.removeSymbolPointSize
      )

      // Keep remove taps in the trailing gutter so title taps never delete the chip.
      let trailingInner = width - input.horizontalPadding
      let gutterStart = titleFrame.maxX
      let gutterWidth = max(0, trailingInner - gutterStart)
      let hitHeight = min(input.height, max(input.removeHitSide, input.removeSymbolPointSize + 8))
      let hitY = (input.height - hitHeight) / 2
      removeHitAreaFrame = CGRect(x: gutterStart, y: hitY, width: gutterWidth, height: hitHeight)
    }

    return Metrics(
      size: bounds.size,
      cornerRadius: cornerRadius,
      leadingIconFrame: leadingIconFrame,
      titleFrame: titleFrame,
      removeButtonFrame: removeButtonFrame,
      removeHitAreaFrame: removeHitAreaFrame
    )
  }

  /// Leading- or trailing-aligned pill frame inside ``bounds`` using precomputed ``Metrics`` (never stretches past natural width).
  static func pillFrame(
    metrics: Metrics,
    in bounds: CGRect,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> CGRect {
    let width = bounds.width > 0 ? min(metrics.size.width, bounds.width) : metrics.size.width
    let height = bounds.height > 0 ? min(metrics.size.height, bounds.height) : metrics.size.height
    let size = CGSize(width: width, height: height)
    let originY = max(0, (bounds.height - height) / 2)
    let originX: CGFloat = switch layoutDirection {
    case .rightToLeft: max(0, bounds.width - width)
    default: 0
    }
    return CGRect(origin: CGPoint(x: originX, y: originY), size: size)
  }
}

/// Renders a widget icon into an image view frame.
enum FKWidgetIconRenderer {
  @MainActor
  static func apply(_ icon: FKWidgetIcon?, to imageView: UIImageView, pointSize: CGFloat, tintColor: UIColor?) {
    guard let icon else {
      imageView.image = nil
      imageView.isHidden = true
      return
    }
    imageView.isHidden = false
    imageView.tintColor = tintColor
    imageView.image = icon.resolvedTemplateImage(pointSize: pointSize)
  }
}
