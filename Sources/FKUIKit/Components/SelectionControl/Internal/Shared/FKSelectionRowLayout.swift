import UIKit

/// Shared layout helpers for indicator + text rows (checkbox / radio).
enum FKSelectionRowLayout {
  struct Metrics {
    var indicatorFrame: CGRect
    var imageFrame: CGRect?
    var titleFrame: CGRect?
    var subtitleFrame: CGRect?
    var contentHeight: CGFloat
  }

  static func metrics(
    in bounds: CGRect,
    size: FKSelectionControlSize,
    contentInsets: NSDirectionalEdgeInsets,
    indicatorEdge: FKSelectionControlIndicatorEdge,
    labelPlacement: FKSelectionControlLabelPlacement,
    indicatorTitleSpacing: CGFloat,
    titleSubtitleSpacing: CGFloat,
    imageSize: CGSize?,
    imageTitleSpacing: CGFloat,
    titleSize: CGSize,
    subtitleSize: CGSize,
    layoutDirection: UIUserInterfaceLayoutDirection,
    rowMinHeight: CGFloat
  ) -> Metrics {
    let side = size.indicatorSide
    let isRTL = layoutDirection == .rightToLeft
    let leadingInset = isRTL ? contentInsets.trailing : contentInsets.leading
    let trailingInset = isRTL ? contentInsets.leading : contentInsets.trailing

    let showLabels = labelPlacement != .hidden
    let hasImage = (imageSize?.width ?? 0) > 0 && (imageSize?.height ?? 0) > 0 && showLabels

    let textBlockHeight: CGFloat
    if showLabels {
      let titleH = titleSize.height
      let subtitleH = subtitleSize.height > 0 ? subtitleSize.height + (titleH > 0 ? titleSubtitleSpacing : 0) : 0
      textBlockHeight = titleH + subtitleH
    } else {
      textBlockHeight = 0
    }

    let imageH = hasImage ? (imageSize?.height ?? 0) : 0
    let centerColumnHeight = max(side, textBlockHeight, imageH)
    let contentHeight = max(rowMinHeight, contentInsets.top + centerColumnHeight + contentInsets.bottom)

    let midY = contentInsets.top + (contentHeight - contentInsets.top - contentInsets.bottom) / 2
    let indicatorY = midY - side / 2

    // `.leading` label placement puts the title first in reading order (indicator on trailing).
    let resolvedIndicatorEdge: FKSelectionControlIndicatorEdge = {
      switch labelPlacement {
      case .leading:
        return .trailing
      case .trailing, .hidden:
        return indicatorEdge
      }
    }()

    let indicatorOnTrailingVisual: Bool = {
      switch resolvedIndicatorEdge {
      case .leading:
        return false
      case .trailing:
        return true
      }
    }()

    // Convert semantic edge to visual left/right considering RTL.
    let indicatorOnVisualRight = isRTL ? !indicatorOnTrailingVisual : indicatorOnTrailingVisual

    let indicatorX: CGFloat
    if indicatorOnVisualRight {
      indicatorX = bounds.width - trailingInset - side
    } else {
      indicatorX = leadingInset
    }
    let indicatorFrame = CGRect(x: indicatorX, y: indicatorY, width: side, height: side)

    var cursorLeading = leadingInset
    var cursorTrailing = bounds.width - trailingInset

    if indicatorOnVisualRight {
      cursorTrailing = indicatorFrame.minX - indicatorTitleSpacing
    } else {
      cursorLeading = indicatorFrame.maxX + indicatorTitleSpacing
    }

    var imageFrame: CGRect?
    if hasImage, let imageSize {
      let imageY = midY - imageSize.height / 2
      if indicatorOnVisualRight {
        // image sits before title, still to the left of trailing indicator
        let imageX = cursorLeading
        imageFrame = CGRect(x: imageX, y: imageY, width: imageSize.width, height: imageSize.height)
        cursorLeading = imageX + imageSize.width + imageTitleSpacing
      } else {
        let imageX = cursorLeading
        imageFrame = CGRect(x: imageX, y: imageY, width: imageSize.width, height: imageSize.height)
        cursorLeading = imageX + imageSize.width + imageTitleSpacing
      }
    }

    var titleFrame: CGRect?
    var subtitleFrame: CGRect?
    if showLabels {
      let availableWidth = max(0, cursorTrailing - cursorLeading)
      let titleWidth = min(titleSize.width, availableWidth)
      let subtitleWidth = min(subtitleSize.width, availableWidth)
      let blockHeight = textBlockHeight
      let blockTop = midY - blockHeight / 2
      if titleSize.height > 0 {
        titleFrame = CGRect(x: cursorLeading, y: blockTop, width: titleWidth, height: titleSize.height)
      }
      if subtitleSize.height > 0 {
        let y = (titleFrame?.maxY ?? blockTop) + (titleFrame != nil ? titleSubtitleSpacing : 0)
        subtitleFrame = CGRect(x: cursorLeading, y: y, width: subtitleWidth, height: subtitleSize.height)
      }
    }

    return Metrics(
      indicatorFrame: indicatorFrame,
      imageFrame: imageFrame,
      titleFrame: titleFrame,
      subtitleFrame: subtitleFrame,
      contentHeight: contentHeight
    )
  }

  static func measureText(
    _ text: String?,
    font: UIFont,
    numberOfLines: Int,
    width: CGFloat
  ) -> CGSize {
    guard let text, !text.isEmpty, width > 0 else { return .zero }
    let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
    let rect = (text as NSString).boundingRect(
      with: constraint,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )
    var height = ceil(rect.height)
    if numberOfLines > 0 {
      let lineHeight = ceil(font.lineHeight)
      height = min(height, lineHeight * CGFloat(numberOfLines))
    }
    return CGSize(width: min(ceil(rect.width), width), height: height)
  }

  static func measureAttributed(
    _ attributed: NSAttributedString?,
    numberOfLines: Int,
    width: CGFloat
  ) -> CGSize {
    guard let attributed, attributed.length > 0, width > 0 else { return .zero }
    let storage = NSTextStorage(attributedString: attributed)
    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0
    container.maximumNumberOfLines = max(0, numberOfLines)
    container.lineBreakMode = .byTruncatingTail
    let manager = NSLayoutManager()
    manager.addTextContainer(container)
    storage.addLayoutManager(manager)
    manager.ensureLayout(for: container)
    let used = manager.usedRect(for: container)
    return CGSize(width: min(ceil(used.width), width), height: ceil(used.height))
  }
}
