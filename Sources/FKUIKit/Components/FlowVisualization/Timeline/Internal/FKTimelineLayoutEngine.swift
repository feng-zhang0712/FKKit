import UIKit

enum FKTimelineLayoutEngine {
  struct RowMetrics: Equatable {
    var nodeFrame: CGRect
    var titleFrame: CGRect
    var subtitleFrame: CGRect?
    var timestampFrame: CGRect?
    var captionFrame: CGRect?
    var connectorFrame: CGRect?
    var contentFrame: CGRect
    var touchFrame: CGRect
    var itemID: String
  }

  struct SectionMetrics: Equatable {
    var titleFrame: CGRect?
    var rows: [RowMetrics]
  }

  struct Metrics: Equatable {
    var sections: [SectionMetrics]
    var contentSize: CGSize
  }

  static func metrics(
    sections: [FKTimelineSection],
    configuration: FKTimelineConfiguration,
    bounds: CGRect,
    layoutDirection: UIUserInterfaceLayoutDirection,
    traitCollection: UITraitCollection?,
    expandedItemIDs: Set<String>
  ) -> Metrics {
    let insets = contentInsets(for: configuration)
    let railSide = resolvedRailSide(
      layout: configuration.layout.layout,
      layoutDirection: layoutDirection,
      respectDirection: configuration.layout.respectInterfaceLayoutDirection
    )
    let nodeDiameter = FKFlowLayoutMetrics.nodeDiameter(
      base: configuration.appearance.nodeSize,
      scalesWithContentSize: configuration.appearance.scalesNodeWithContentSize,
      traitCollection: traitCollection
    )
    let textX: CGFloat
    let nodeX: CGFloat
    let availableTextWidth: CGFloat

    switch railSide {
    case .leading:
      nodeX = insets.left
      textX = nodeX + nodeDiameter + configuration.layout.railSpacing
      availableTextWidth = max(0, bounds.width - textX - insets.right)
    case .trailing:
      nodeX = bounds.width - insets.right - nodeDiameter
      textX = insets.left
      availableTextWidth = max(0, nodeX - configuration.layout.railSpacing - textX)
    }

    var y = insets.top
    var sectionMetrics: [SectionMetrics] = []

    for (sectionIndex, section) in sections.enumerated() {
      var titleFrame: CGRect?
      if !section.title.isEmpty {
        let titleHeight = sectionTitleHeight(configuration: configuration)
        titleFrame = CGRect(x: textX, y: y, width: availableTextWidth, height: titleHeight)
        y += titleHeight + FKFlowLayoutMetrics.labelSpacing(configuration.appearance.density)
      }

      var rows: [RowMetrics] = []
      for (rowIndex, item) in section.items.enumerated() {
        let isExpanded = expandedItemIDs.contains(item.id)
        let timestamp = FKTimelineTimestampFormatter.string(for: item, style: configuration.layout.timestampStyle)
        let titleHeight = textHeight(
          item.title,
          font: titleFont(for: item, configuration: configuration),
          width: availableTextWidth,
          lines: configuration.layout.titleNumberOfLines
        )
        let subtitleHeight = item.subtitle.map {
          textHeight($0, font: configuration.appearance.subtitleFont, width: availableTextWidth, lines: configuration.layout.subtitleNumberOfLines)
        } ?? 0
        let timestampHeight = timestamp.map {
          textHeight($0, font: configuration.appearance.timestampFont, width: availableTextWidth, lines: 1)
        } ?? 0
        let captionHeight: CGFloat = {
          guard isExpanded, let caption = item.caption, !caption.isEmpty else { return 0 }
          let lines = configuration.layout.captionNumberOfLines
          if lines == 0 { return textHeight(caption, font: configuration.appearance.captionFont, width: availableTextWidth, lines: 99) }
          return textHeight(caption, font: configuration.appearance.captionFont, width: availableTextWidth, lines: lines)
        }()

        var textY = y
        let titleFrame = CGRect(x: textX, y: textY, width: availableTextWidth, height: titleHeight)
        textY += titleHeight + (subtitleHeight > 0 || timestampHeight > 0 ? 2 : 0)

        let subtitleFrame: CGRect? = subtitleHeight > 0
          ? CGRect(x: textX, y: textY, width: availableTextWidth, height: subtitleHeight)
          : nil
        if subtitleHeight > 0 { textY += subtitleHeight + 2 }

        let timestampFrame: CGRect? = timestampHeight > 0
          ? CGRect(x: textX, y: textY, width: availableTextWidth, height: timestampHeight)
          : nil
        if timestampHeight > 0 { textY += timestampHeight + 2 }

        let captionFrame: CGRect? = captionHeight > 0
          ? CGRect(x: textX, y: textY, width: availableTextWidth, height: captionHeight)
          : nil
        if captionHeight > 0 { textY += captionHeight }

        let rowContentHeight = max(textY - y, nodeDiameter)
        let nodeFrame = CGRect(x: nodeX, y: y, width: nodeDiameter, height: nodeDiameter)
        let contentFrame = CGRect(x: textX, y: y, width: availableTextWidth, height: rowContentHeight)

        var connectorFrame: CGRect?
        let isLastInSection = rowIndex == section.items.count - 1
        let isLastOverall = isLastInSection && sectionIndex == sections.count - 1
        if !isLastOverall || configuration.layout.tailStyle != .none {
          let connectorTop = nodeFrame.maxY
          let connectorBottom: CGFloat
          if isLastOverall {
            connectorBottom = y + rowContentHeight + rowSpacing(configuration: configuration)
          } else {
            var nextRowY = y + rowContentHeight + rowSpacing(configuration: configuration)
            if isLastInSection {
              let nextSection = sections[sectionIndex + 1]
              if !nextSection.title.isEmpty {
                nextRowY += sectionTitleHeight(configuration: configuration)
                  + FKFlowLayoutMetrics.labelSpacing(configuration.appearance.density)
              }
            }
            connectorBottom = nextRowY + nodeDiameter * 0.5
          }
          connectorFrame = CGRect(
            x: nodeFrame.midX - configuration.appearance.connector.thickness * 0.5,
            y: connectorTop,
            width: configuration.appearance.connector.thickness,
            height: max(connectorBottom - connectorTop, rowSpacing(configuration: configuration))
          )
        }

        let touchFrame = expandedTouchFrame(around: nodeFrame, minimum: configuration.interaction.minimumTouchTargetSize)
          .union(contentFrame)

        rows.append(
          RowMetrics(
            nodeFrame: nodeFrame,
            titleFrame: titleFrame,
            subtitleFrame: subtitleFrame,
            timestampFrame: timestampFrame,
            captionFrame: captionFrame,
            connectorFrame: connectorFrame,
            contentFrame: contentFrame,
            touchFrame: touchFrame,
            itemID: item.id
          )
        )

        y += rowContentHeight + rowSpacing(configuration: configuration)
      }

      sectionMetrics.append(SectionMetrics(titleFrame: titleFrame, rows: rows))
    }

    y += insets.bottom
    return Metrics(sections: sectionMetrics, contentSize: CGSize(width: bounds.width, height: y))
  }

  private enum RailSide {
    case leading
    case trailing
  }

  private static func resolvedRailSide(
    layout: FKTimelineLayout,
    layoutDirection: UIUserInterfaceLayoutDirection,
    respectDirection: Bool
  ) -> RailSide {
    switch layout {
    case .verticalTrailingRail:
      return .trailing
    case .verticalLeadingRail, .embeddedInList:
      if respectDirection, layoutDirection == .rightToLeft { return .trailing }
      return .leading
    case .verticalAlternating:
      return .leading
    }
  }

  private static func contentInsets(for configuration: FKTimelineConfiguration) -> UIEdgeInsets {
    if configuration.layout.layout == .embeddedInList {
      return FKFlowLayoutMetrics.contentInsets(for: configuration.appearance.density, embedded: true)
    }
    return configuration.layout.contentInsets
  }

  private static func rowSpacing(configuration: FKTimelineConfiguration) -> CGFloat {
    if configuration.layout.rowSpacing > 0 { return configuration.layout.rowSpacing }
    return FKFlowLayoutMetrics.densitySpacing(configuration.appearance.density, axis: .vertical)
  }

  private static func sectionTitleHeight(configuration: FKTimelineConfiguration) -> CGFloat {
    configuration.layout.sectionTitleFont.lineHeight
  }

  private static func textHeight(_ text: String, font: UIFont, width: CGFloat, lines: Int) -> CGFloat {
    guard !text.isEmpty else { return 0 }
    let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
    let rect = (text as NSString).boundingRect(
      with: constraint,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )
    let maxHeight = font.lineHeight * CGFloat(max(1, lines))
    return min(max(rect.height.rounded(.up), font.lineHeight), maxHeight)
  }

  private static func titleFont(for item: FKFlowStepItem, configuration: FKTimelineConfiguration) -> UIFont {
    guard configuration.appearance.emphasizesCurrentTitle, item.state == .current else {
      return configuration.appearance.titleFont
    }
    return UIFont.systemFont(ofSize: configuration.appearance.titleFont.pointSize, weight: .semibold)
  }

  private static func expandedTouchFrame(around nodeFrame: CGRect, minimum: CGSize) -> CGRect {
    let dx = max(0, (minimum.width - nodeFrame.width) * 0.5)
    let dy = max(0, (minimum.height - nodeFrame.height) * 0.5)
    return nodeFrame.insetBy(dx: -dx, dy: -dy)
  }
}
