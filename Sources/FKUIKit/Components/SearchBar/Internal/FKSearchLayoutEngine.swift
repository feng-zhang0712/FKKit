import UIKit

enum FKSearchLayoutEngine {
  struct Metrics: Equatable {
    var chromeFrame: CGRect
    var searchIconFrame: CGRect
    var textFieldFrame: CGRect
    var loadingIndicatorFrame: CGRect
    var clearButtonFrame: CGRect
    var cancelButtonFrame: CGRect
    var underlineFrame: CGRect?
    var barHeight: CGFloat
  }

  struct Input {
    var bounds: CGRect
    var layout: FKSearchLayoutConfiguration
    var appearance: FKSearchAppearanceConfiguration
    var showsCancelButton: Bool
    var isCancelVisible: Bool
    var showsClearButton: Bool
    var showsLoadingIndicator: Bool
    var cancelTitleSize: CGSize
    var layoutDirection: UIUserInterfaceLayoutDirection
    var scaledTextFont: UIFont
  }

  static func metrics(for input: Input) -> Metrics {
    let barHeight = resolvedBarHeight(input: input)
    let chromeFrame = CGRect(x: 0, y: 0, width: input.bounds.width, height: barHeight)
    let contentHeight = barHeight
    let minTap: CGFloat = 44
    let iconSize = input.appearance.leadingIcon.pointSize
    let trailingAccessorySize = max(iconSize, minTap)

    let showsCancel = input.showsCancelButton && input.isCancelVisible
    let cancelWidth = showsCancel ? input.cancelTitleSize.width + 16 : 0
    let cancelSpacing: CGFloat = showsCancel ? 8 : 0

    var leadingX = input.layout.horizontalPadding
    if input.layoutDirection == .rightToLeft {
      leadingX = input.bounds.width - input.layout.horizontalPadding
    }

    let searchIconHidden = input.appearance.leadingIcon.isHidden
    let searchIconFrame: CGRect
    if searchIconHidden {
      searchIconFrame = .zero
    } else if input.layoutDirection == .rightToLeft {
      searchIconFrame = CGRect(
        x: leadingX - iconSize,
        y: (contentHeight - iconSize) / 2,
        width: iconSize,
        height: iconSize
      )
      leadingX -= iconSize + input.layout.iconSpacing
    } else {
      searchIconFrame = CGRect(
        x: leadingX,
        y: (contentHeight - iconSize) / 2,
        width: iconSize,
        height: iconSize
      )
      leadingX += iconSize + input.layout.iconSpacing
    }

    let trailingXStart: CGFloat
    if input.layoutDirection == .rightToLeft {
      trailingXStart = input.layout.horizontalPadding + cancelWidth + cancelSpacing
    } else {
      trailingXStart = input.bounds.width - input.layout.horizontalPadding - cancelWidth - cancelSpacing
    }

    var trailingCursor = trailingXStart
    let clearFrame: CGRect
    if input.showsClearButton {
      if input.layoutDirection == .rightToLeft {
        clearFrame = CGRect(
          x: trailingCursor,
          y: (contentHeight - trailingAccessorySize) / 2,
          width: trailingAccessorySize,
          height: trailingAccessorySize
        )
        trailingCursor += trailingAccessorySize
      } else {
        trailingCursor -= trailingAccessorySize
        clearFrame = CGRect(
          x: trailingCursor,
          y: (contentHeight - trailingAccessorySize) / 2,
          width: trailingAccessorySize,
          height: trailingAccessorySize
        )
      }
    } else {
      clearFrame = .zero
    }

    let loadingFrame: CGRect
    if input.showsLoadingIndicator {
      if input.layoutDirection == .rightToLeft {
        loadingFrame = CGRect(
          x: trailingCursor,
          y: (contentHeight - trailingAccessorySize) / 2,
          width: trailingAccessorySize,
          height: trailingAccessorySize
        )
        trailingCursor += trailingAccessorySize
      } else {
        trailingCursor -= trailingAccessorySize
        loadingFrame = CGRect(
          x: trailingCursor,
          y: (contentHeight - trailingAccessorySize) / 2,
          width: trailingAccessorySize,
          height: trailingAccessorySize
        )
      }
    } else {
      loadingFrame = .zero
    }

    let textFieldX: CGFloat
    let textFieldWidth: CGFloat
    if input.layoutDirection == .rightToLeft {
      textFieldWidth = max(0, leadingX - trailingCursor - input.layout.iconSpacing)
      textFieldX = trailingCursor
    } else {
      textFieldX = leadingX
      textFieldWidth = max(0, trailingCursor - leadingX)
    }

    let textFieldFrame = CGRect(
      x: textFieldX,
      y: 0,
      width: textFieldWidth,
      height: contentHeight
    )

    let cancelButtonFrame: CGRect
    if showsCancel {
      if input.layoutDirection == .rightToLeft {
        cancelButtonFrame = CGRect(
          x: input.layout.horizontalPadding,
          y: 0,
          width: cancelWidth,
          height: contentHeight
        )
      } else {
        cancelButtonFrame = CGRect(
          x: input.bounds.width - input.layout.horizontalPadding - cancelWidth,
          y: 0,
          width: cancelWidth,
          height: contentHeight
        )
      }
    } else {
      cancelButtonFrame = .zero
    }

    let underlineFrame: CGRect?
    if input.layout.showsUnderline || input.layout.style == .minimal {
      let y = contentHeight - 1
      underlineFrame = CGRect(x: 0, y: y, width: input.bounds.width, height: 1)
    } else {
      underlineFrame = nil
    }

    return Metrics(
      chromeFrame: chromeFrame,
      searchIconFrame: searchIconFrame,
      textFieldFrame: textFieldFrame,
      loadingIndicatorFrame: loadingFrame,
      clearButtonFrame: clearFrame,
      cancelButtonFrame: cancelButtonFrame,
      underlineFrame: underlineFrame,
      barHeight: barHeight
    )
  }

  static func intrinsicContentSize(
    layout: FKSearchLayoutConfiguration,
    appearance: FKSearchAppearanceConfiguration,
    showsCancelButton: Bool,
    isCancelVisible: Bool,
    cancelTitleSize: CGSize,
    proposedWidth: CGFloat
  ) -> CGSize {
    let height = resolvedBarHeight(
      input: Input(
        bounds: CGRect(x: 0, y: 0, width: proposedWidth, height: 0),
        layout: layout,
        appearance: appearance,
        showsCancelButton: showsCancelButton,
        isCancelVisible: isCancelVisible,
        showsClearButton: false,
        showsLoadingIndicator: false,
        cancelTitleSize: cancelTitleSize,
        layoutDirection: .leftToRight,
        scaledTextFont: scaledFont(for: appearance, layout: layout)
      )
    )
    return CGSize(width: UIView.noIntrinsicMetric, height: height)
  }

  static func resolvedCornerRadius(
    layout: FKSearchLayoutConfiguration,
    appearance: FKSearchAppearanceConfiguration,
    barHeight: CGFloat
  ) -> CGFloat {
    switch appearance.cornerStyle {
    case .none:
      return 0
    case let .fixed(radius):
      return radius
    case .capsule:
      switch layout.style {
      case .inlineCard, .compactToolbar:
        return barHeight / 2
      case .navigationBar, .minimal:
        return 10
      }
    }
  }

  private static func resolvedBarHeight(input: Input) -> CGFloat {
    let base = switch input.layout.style {
    case .navigationBar, .inlineCard, .minimal:
      input.layout.minimumHeight
    case .compactToolbar:
      max(36, input.layout.minimumHeight - 8)
    }
    guard input.layout.growsWithDynamicType else { return base }
    let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(for: base)
    return max(input.layout.minimumHeight, scaled)
  }

  static func scaledFont(for appearance: FKSearchAppearanceConfiguration, layout: FKSearchLayoutConfiguration) -> UIFont {
    guard layout.growsWithDynamicType else { return appearance.textStyle.font }
    return UIFontMetrics(forTextStyle: .body).scaledFont(for: appearance.textStyle.font)
  }
}
