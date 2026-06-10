#if canImport(SwiftUI)
  import SwiftUI
  import UIKit

  /// SwiftUI wrapper around ``FKMarqueeLabel``.
  public struct FKMarqueeLabelRepresentable: UIViewRepresentable {
    public var configuration: FKMarqueeLabelConfiguration
    public var text: String
    public var isPaused: Bool

    public init(
      configuration: FKMarqueeLabelConfiguration = FKMarqueeLabel.defaultConfiguration,
      text: String = "",
      isPaused: Bool = false
    ) {
      self.configuration = configuration
      self.text = text
      self.isPaused = isPaused
    }

    public func makeUIView(context: Context) -> FKMarqueeLabel {
      let label = FKMarqueeLabel(configuration: configuration, text: text)
      label.isPaused = isPaused
      return label
    }

    public func updateUIView(_ uiView: FKMarqueeLabel, context: Context) {
      uiView.configuration = configuration
      uiView.text = text
      uiView.isPaused = isPaused
    }
  }
#endif
