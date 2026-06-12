import UIKit

enum FKStepIndicatorLayoutEngine {
  struct StepMetrics: Equatable {
    var nodeFrame: CGRect
    var titleFrame: CGRect?
    var subtitleFrame: CGRect?
    var connectorStart: CGPoint?
    var connectorEnd: CGPoint?
    var touchFrame: CGRect
  }

  struct Metrics: Equatable {
    var stepMetrics: [StepMetrics]
    var contentSize: CGSize
    var needsHorizontalScroll: Bool
  }

  static func metrics(
    items: [FKFlowStepItem],
    configuration: FKStepIndicatorConfiguration,
    bounds: CGRect,
    layoutDirection: UIUserInterfaceLayoutDirection,
    traitCollection: UITraitCollection?
  ) -> Metrics {
    guard !items.isEmpty else {
      return Metrics(stepMetrics: [], contentSize: .zero, needsHorizontalScroll: false)
    }

    let insets = configuration.layout.contentInsets
    let availableWidth = max(0, bounds.width - insets.left - insets.right)
    let nodeDiameter = FKFlowLayoutMetrics.nodeDiameter(
      base: configuration.appearance.nodeSize,
      scalesWithContentSize: configuration.appearance.scalesNodeWithContentSize,
      traitCollection: traitCollection
    )
    let touchSize = configuration.interaction.minimumTouchTargetSize
    let labelSpacing = FKFlowLayoutMetrics.labelSpacing(configuration.appearance.density)
    let baseTitleFont = emphasizedFont(
      base: configuration.appearance.titleFont,
      emphasized: configuration.appearance.emphasizesCurrentTitle
    )
    let subtitleFont = configuration.appearance.subtitleFont

    let itemCount = items.count
    var spacing = configuration.layout.stepSpacing
    var pitch = nodeDiameter + spacing

    var stepMetrics: [StepMetrics] = []
    stepMetrics.reserveCapacity(itemCount)

    var nodePositions: [CGFloat] = []
    nodePositions.reserveCapacity(itemCount)
    var inlineLabelWidths: [CGFloat] = []

    switch configuration.layout.layout {
    case .horizontalInline:
      var x = insets.left
      for index in 0 ..< itemCount {
        let item = items[index]
        nodePositions.append(x)
        let titleFont = resolvedTitleFont(for: item, base: baseTitleFont, configuration: configuration)
        let titleWidth = naturalTextWidth(
          text: item.title,
          font: titleFont,
          lines: configuration.layout.titleNumberOfLines
        )
        let subtitleWidth = item.subtitle.map {
          naturalTextWidth(
            text: $0,
            font: subtitleFont,
            lines: configuration.layout.subtitleNumberOfLines
          )
        } ?? 0
        let labelWidth = max(titleWidth, subtitleWidth)
        inlineLabelWidths.append(labelWidth)
        x += nodeDiameter + labelSpacing + labelWidth + spacing
      }

    case .horizontalTopLabels, .horizontalBottomLabels, .compactDots:
      func assignRailPositions(using stepSpacing: CGFloat) {
        nodePositions.removeAll(keepingCapacity: true)
        let totalNodesWidth = CGFloat(itemCount) * nodeDiameter + CGFloat(max(0, itemCount - 1)) * stepSpacing
        let needsScrollForLayout = scrollNeeded(
          itemCount: itemCount,
          totalNodesWidth: totalNodesWidth,
          availableWidth: availableWidth,
          maxVisibleSteps: configuration.layout.maxVisibleSteps
        )
        let originX: CGFloat = needsScrollForLayout
          ? insets.left
          : insets.left + max(0, (availableWidth - totalNodesWidth) * 0.5)
        for index in 0 ..< itemCount {
          nodePositions.append(originX + CGFloat(index) * (nodeDiameter + stepSpacing))
        }
      }

      assignRailPositions(using: spacing)

      let exceedsVisibleStepLimit = configuration.layout.maxVisibleSteps > 0
        && itemCount > configuration.layout.maxVisibleSteps
      if !exceedsVisibleStepLimit {
        let trackWidth = CGFloat(itemCount) * nodeDiameter + CGFloat(max(0, itemCount - 1)) * spacing
        if trackWidth <= availableWidth {
          spacing = (availableWidth + 1 - CGFloat(itemCount) * nodeDiameter) / CGFloat(max(1, itemCount - 1))
          pitch = nodeDiameter + spacing
          assignRailPositions(using: spacing)
        }
      }
    }

    let isRailLayout: Bool = {
      switch configuration.layout.layout {
      case .horizontalTopLabels, .horizontalBottomLabels, .compactDots: return true
      default: return false
      }
    }()
    let railNaturalLabelWidths: [CGFloat] = {
      guard isRailLayout else { return [] }
      return items.map { item in
        naturalRailLabelWidth(
          for: item,
          baseTitleFont: baseTitleFont,
          subtitleFont: subtitleFont,
          configuration: configuration
        )
      }
    }()

    let uniformBottomLabelsNodeY: CGFloat? = {
      guard configuration.layout.layout == .horizontalBottomLabels else { return nil }
      var maxLabelsBlockHeight: CGFloat = 0
      for visualIndex in 0 ..< itemCount {
        let logicalIndex = layoutDirection == .rightToLeft ? (itemCount - 1 - visualIndex) : visualIndex
        let item = items[logicalIndex]
        let x = nodePositions[visualIndex]
        let labelWidth = labelWidthForStep(
          at: visualIndex,
          itemCount: itemCount,
          nodeX: x,
          pitch: pitch,
          nodeDiameter: nodeDiameter,
          spacing: spacing,
          availableWidth: availableWidth,
          insets: insets,
          layout: configuration.layout.layout,
          nextNodeX: visualIndex + 1 < itemCount ? nodePositions[visualIndex + 1] : nil,
          inlineLabelWidth: nil,
          naturalRailLabelWidth: railNaturalLabelWidth(at: visualIndex, itemCount: itemCount, isRailLayout: isRailLayout, widths: railNaturalLabelWidths, logicalIndex: logicalIndex)
        )
        let titleSize = measure(
          text: item.title,
          font: resolvedTitleFont(for: item, base: baseTitleFont, configuration: configuration),
          width: labelWidth,
          lines: configuration.layout.titleNumberOfLines
        )
        let subtitleSize = item.subtitle.map {
          measure(
            text: $0,
            font: subtitleFont,
            width: labelWidth,
            lines: configuration.layout.subtitleNumberOfLines
          )
        } ?? .zero
        let labelsBlockHeight = titleSize.height + (subtitleSize == .zero ? 0 : subtitleSize.height + 2)
        maxLabelsBlockHeight = max(maxLabelsBlockHeight, labelsBlockHeight)
      }
      return insets.top + maxLabelsBlockHeight + labelSpacing
    }()

    let inlineConnectorY: CGFloat? = {
      guard configuration.layout.layout == .horizontalInline else { return nil }
      var maxBlockHeight: CGFloat = 0
      for visualIndex in 0 ..< itemCount {
        let logicalIndex = layoutDirection == .rightToLeft ? (itemCount - 1 - visualIndex) : visualIndex
        let item = items[logicalIndex]
        let labelWidth = inlineLabelWidths[visualIndex]
        let titleSize = measure(
          text: item.title,
          font: resolvedTitleFont(for: item, base: baseTitleFont, configuration: configuration),
          width: labelWidth,
          lines: configuration.layout.titleNumberOfLines
        )
        let subtitleSize = item.subtitle.map {
          measure(
            text: $0,
            font: subtitleFont,
            width: labelWidth,
            lines: configuration.layout.subtitleNumberOfLines
          )
        } ?? .zero
        let besideHeight = max(nodeDiameter, titleSize.height)
        let blockHeight = besideHeight + (subtitleSize == .zero ? 0 : labelSpacing + subtitleSize.height)
        maxBlockHeight = max(maxBlockHeight, blockHeight)
      }
      return insets.top + maxBlockHeight + labelSpacing
    }()

    var maxContentHeight: CGFloat = 0
    var maxContentRight = insets.left

    for visualIndex in 0 ..< itemCount {
      let logicalIndex = layoutDirection == .rightToLeft ? (itemCount - 1 - visualIndex) : visualIndex
      let item = items[logicalIndex]
      let x = nodePositions[visualIndex]
      let labelWidth = labelWidthForStep(
        at: visualIndex,
        itemCount: itemCount,
        nodeX: x,
        pitch: pitch,
        nodeDiameter: nodeDiameter,
        spacing: spacing,
        availableWidth: availableWidth,
        insets: insets,
        layout: configuration.layout.layout,
        nextNodeX: visualIndex + 1 < itemCount ? nodePositions[visualIndex + 1] : nil,
        inlineLabelWidth: configuration.layout.layout == .horizontalInline ? inlineLabelWidths[visualIndex] : nil,
        naturalRailLabelWidth: railNaturalLabelWidth(at: visualIndex, itemCount: itemCount, isRailLayout: isRailLayout, widths: railNaturalLabelWidths, logicalIndex: logicalIndex)
      )

      let nodeY: CGFloat
      let titleFrame: CGRect?
      let subtitleFrame: CGRect?

      let titleSize = measure(
        text: item.title,
        font: resolvedTitleFont(for: item, base: baseTitleFont, configuration: configuration),
        width: labelWidth,
        lines: configuration.layout.titleNumberOfLines
      )
      let subtitleSize = item.subtitle.map {
        measure(
          text: $0,
          font: subtitleFont,
          width: labelWidth,
          lines: configuration.layout.subtitleNumberOfLines
        )
      } ?? .zero

      switch configuration.layout.layout {
      case .horizontalTopLabels, .compactDots:
        nodeY = insets.top
        let labelsY = nodeY + nodeDiameter + labelSpacing
        let labelX = railLabelOriginX(nodeX: x, nodeDiameter: nodeDiameter, labelWidth: labelWidth)
        titleFrame = titleSize == .zero ? nil : CGRect(
          x: labelX,
          y: labelsY,
          width: labelWidth,
          height: titleSize.height
        )
        let subtitleY = (titleFrame?.maxY ?? labelsY) + (titleFrame == nil ? 0 : 2)
        subtitleFrame = subtitleSize == .zero ? nil : CGRect(
          x: labelX,
          y: subtitleY,
          width: labelWidth,
          height: subtitleSize.height
        )
        maxContentHeight = max(maxContentHeight, (subtitleFrame?.maxY ?? titleFrame?.maxY ?? nodeY + nodeDiameter) + insets.bottom)

      case .horizontalBottomLabels:
        let labelsY = insets.top
        let labelX = railLabelOriginX(nodeX: x, nodeDiameter: nodeDiameter, labelWidth: labelWidth)
        titleFrame = titleSize == .zero ? nil : CGRect(
          x: labelX,
          y: labelsY,
          width: labelWidth,
          height: titleSize.height
        )
        let subtitleY = (titleFrame?.maxY ?? labelsY) + (titleFrame == nil ? 0 : 2)
        subtitleFrame = subtitleSize == .zero ? nil : CGRect(
          x: labelX,
          y: subtitleY,
          width: labelWidth,
          height: subtitleSize.height
        )
        nodeY = uniformBottomLabelsNodeY ?? (labelsY + titleSize.height + (subtitleSize == .zero ? 0 : subtitleSize.height + 2) + labelSpacing)
        maxContentHeight = max(maxContentHeight, nodeY + nodeDiameter + insets.bottom)

      case .horizontalInline:
        nodeY = insets.top
        titleFrame = titleSize == .zero ? nil : CGRect(
          x: x + nodeDiameter + labelSpacing,
          y: nodeY,
          width: labelWidth,
          height: titleSize.height
        )
        let besideHeight = max(nodeDiameter, titleSize.height)
        let subtitleY = nodeY + besideHeight + labelSpacing
        subtitleFrame = subtitleSize == .zero ? nil : CGRect(
          x: x + nodeDiameter + labelSpacing,
          y: subtitleY,
          width: labelWidth,
          height: subtitleSize.height
        )
        let connectorY = inlineConnectorY ?? subtitleY
        maxContentHeight = max(maxContentHeight, connectorY + labelSpacing + insets.bottom)
      }

      let nodeFrame = CGRect(x: x, y: nodeY, width: nodeDiameter, height: nodeDiameter)
      let touchFrame = expandedTouchFrame(around: nodeFrame, minimum: touchSize)

      var connectorStart: CGPoint?
      var connectorEnd: CGPoint?
      if visualIndex < itemCount - 1 {
        let nextNodeX = nodePositions[visualIndex + 1]
        if configuration.layout.layout == .horizontalInline, let connectorY = inlineConnectorY {
          connectorStart = CGPoint(x: nodeFrame.midX, y: connectorY)
          connectorEnd = CGPoint(x: nextNodeX + nodeDiameter * 0.5, y: connectorY)
        } else {
          connectorStart = CGPoint(x: nodeFrame.maxX, y: nodeFrame.midY)
          connectorEnd = CGPoint(x: nextNodeX, y: nodeFrame.midY)
        }
      }

      stepMetrics.append(
        StepMetrics(
          nodeFrame: nodeFrame,
          titleFrame: titleFrame,
          subtitleFrame: subtitleFrame,
          connectorStart: connectorStart,
          connectorEnd: connectorEnd,
          touchFrame: touchFrame
        )
      )

      maxContentRight = max(maxContentRight, nodeFrame.maxX)
      if let titleFrame { maxContentRight = max(maxContentRight, titleFrame.maxX) }
      if let subtitleFrame { maxContentRight = max(maxContentRight, subtitleFrame.maxX) }
      if let connectorEnd { maxContentRight = max(maxContentRight, connectorEnd.x) }
    }

    let nodeTrackWidth: CGFloat = {
      guard let last = nodePositions.last else { return 0 }
      if configuration.layout.layout == .horizontalInline, let lastIndex = nodePositions.indices.last {
        return last + nodeDiameter + labelSpacing + inlineLabelWidths[lastIndex] - insets.left
      }
      return last + nodeDiameter - insets.left
    }()
    let contentTrackWidth = max(nodeTrackWidth, maxContentRight - insets.left)
    let needsScroll = scrollNeeded(
      itemCount: itemCount,
      totalNodesWidth: contentTrackWidth,
      availableWidth: availableWidth,
      maxVisibleSteps: configuration.layout.maxVisibleSteps
    )

    if layoutDirection == .rightToLeft {
      stepMetrics = mirror(metrics: stepMetrics, width: max(bounds.width, insets.left + contentTrackWidth + insets.right))
    }

    let contentWidth = needsScroll
      ? insets.left + contentTrackWidth + insets.right
      : max(bounds.width, insets.left + contentTrackWidth + insets.right)

    return Metrics(
      stepMetrics: stepMetrics,
      contentSize: CGSize(width: contentWidth, height: maxContentHeight),
      needsHorizontalScroll: needsScroll
    )
  }

  static func intrinsicContentSize(
    items: [FKFlowStepItem],
    configuration: FKStepIndicatorConfiguration,
    width: CGFloat,
    traitCollection: UITraitCollection?
  ) -> CGSize {
    let metrics = metrics(
      items: items,
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude),
      layoutDirection: .leftToRight,
      traitCollection: traitCollection
    )
    return metrics.contentSize
  }

  private static func scrollNeeded(
    itemCount: Int,
    totalNodesWidth: CGFloat,
    availableWidth: CGFloat,
    maxVisibleSteps: Int
  ) -> Bool {
    if maxVisibleSteps > 0, itemCount > maxVisibleSteps { return true }
    return totalNodesWidth > availableWidth
  }

  private static func labelWidthForStep(
    at index: Int,
    itemCount: Int,
    nodeX: CGFloat,
    pitch: CGFloat,
    nodeDiameter: CGFloat,
    spacing: CGFloat,
    availableWidth: CGFloat,
    insets: UIEdgeInsets,
    layout: FKStepIndicatorLayout,
    nextNodeX: CGFloat?,
    inlineLabelWidth: CGFloat?,
    naturalRailLabelWidth: CGFloat? = nil
  ) -> CGFloat {
    switch layout {
    case .horizontalInline:
      if let inlineLabelWidth {
        return max(nodeDiameter, inlineLabelWidth)
      }
      if let nextNodeX {
        return max(nodeDiameter, nextNodeX - nodeX - nodeDiameter - spacing)
      }
      return max(nodeDiameter, availableWidth + insets.left - nodeX - nodeDiameter - spacing)

    case .horizontalTopLabels, .horizontalBottomLabels, .compactDots:
      if index == 0 || index + 1 >= itemCount, let naturalRailLabelWidth {
        return max(nodeDiameter, naturalRailLabelWidth)
      }
      if let nextNodeX {
        let maxWidth = pitch - 2
        return min(maxWidth, max(nodeDiameter, nextNodeX - nodeX - 2))
      }
      let nodeCenterX = nodeX + nodeDiameter * 0.5
      return max(nodeDiameter, 2 * (contentRight(from: insets, availableWidth: availableWidth) - nodeCenterX))
    }
  }

  private static func railNaturalLabelWidth(
    at visualIndex: Int,
    itemCount: Int,
    isRailLayout: Bool,
    widths: [CGFloat],
    logicalIndex: Int
  ) -> CGFloat? {
    guard isRailLayout, visualIndex == 0 || visualIndex + 1 >= itemCount else { return nil }
    guard logicalIndex >= 0, logicalIndex < widths.count else { return nil }
    return widths[logicalIndex]
  }

  private static func contentRight(from insets: UIEdgeInsets, availableWidth: CGFloat) -> CGFloat {
    insets.left + availableWidth
  }

  private static func naturalRailLabelWidth(
    for item: FKFlowStepItem,
    baseTitleFont: UIFont,
    subtitleFont: UIFont,
    configuration: FKStepIndicatorConfiguration
  ) -> CGFloat {
    let titleFont = resolvedTitleFont(for: item, base: baseTitleFont, configuration: configuration)
    let titleWidth = naturalTextWidth(
      text: item.title,
      font: titleFont,
      lines: configuration.layout.titleNumberOfLines
    )
    let subtitleWidth = item.subtitle.map {
      naturalTextWidth(
        text: $0,
        font: subtitleFont,
        lines: configuration.layout.subtitleNumberOfLines
      )
    } ?? 0
    return max(titleWidth, subtitleWidth)
  }

  private static func railLabelOriginX(nodeX: CGFloat, nodeDiameter: CGFloat, labelWidth: CGFloat) -> CGFloat {
    nodeX + (nodeDiameter - labelWidth) * 0.5
  }

  private static func naturalTextWidth(text: String, font: UIFont, lines: Int) -> CGFloat {
    guard !text.isEmpty else { return 0 }
    let constraint = CGSize(width: .greatestFiniteMagnitude, height: font.lineHeight * CGFloat(max(1, lines)))
    let rect = (text as NSString).boundingRect(
      with: constraint,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )
    return min(rect.width.rounded(.up), constraint.width)
  }

  private static func measure(text: String, font: UIFont, width: CGFloat, lines: Int) -> CGSize {
    guard !text.isEmpty, width > 0 else { return .zero }
    let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    let rect = (text as NSString).boundingRect(
      with: constraint,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: attributes,
      context: nil
    )
    let lineHeight = font.lineHeight * CGFloat(lines)
    return CGSize(width: width, height: min(max(rect.height.rounded(.up), font.lineHeight), lineHeight))
  }

  private static func emphasizedFont(base: UIFont, emphasized: Bool) -> UIFont {
    guard emphasized else { return base }
    return base.withWeight(.semibold) ?? base
  }

  private static func resolvedTitleFont(
    for item: FKFlowStepItem,
    base: UIFont,
    configuration: FKStepIndicatorConfiguration
  ) -> UIFont {
    guard configuration.appearance.emphasizesCurrentTitle, item.state == .current else { return base }
    return base.withWeight(.semibold) ?? base
  }

  private static func expandedTouchFrame(around nodeFrame: CGRect, minimum: CGSize) -> CGRect {
    let dx = max(0, (minimum.width - nodeFrame.width) * 0.5)
    let dy = max(0, (minimum.height - nodeFrame.height) * 0.5)
    return nodeFrame.insetBy(dx: -dx, dy: -dy)
  }

  private static func mirror(metrics: [StepMetrics], width: CGFloat) -> [StepMetrics] {
    metrics.map { step in
      StepMetrics(
        nodeFrame: step.nodeFrame.mirrored(in: width),
        titleFrame: step.titleFrame?.mirrored(in: width),
        subtitleFrame: step.subtitleFrame?.mirrored(in: width),
        connectorStart: step.connectorStart.map { CGPoint(x: width - $0.x, y: $0.y) },
        connectorEnd: step.connectorEnd.map { CGPoint(x: width - $0.x, y: $0.y) },
        touchFrame: step.touchFrame.mirrored(in: width)
      )
    }
  }
}

private extension CGRect {
  func mirrored(in width: CGFloat) -> CGRect {
    CGRect(x: width - maxX, y: minY, width: self.width, height: self.height)
  }
}

private extension UIFont {
  func withWeight(_ weight: UIFont.Weight) -> UIFont? {
    guard let descriptor = fontDescriptor.withSymbolicTraits([])?.addingAttributes([
      .traits: [UIFontDescriptor.TraitKey.weight: weight],
    ]) else {
      return UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}
