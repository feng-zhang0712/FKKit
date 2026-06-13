#if canImport(SwiftUI)
  import SwiftUI
  import UIKit

  /// SwiftUI wrapper around ``FKIconView`` preserving size tokens and tint.
  public struct FKIconViewRepresentable: UIViewRepresentable {
    public var configuration: FKIconViewConfiguration
    public var symbolName: String?
    public var image: UIImage?
    public var tintColor: UIColor?

    public init(
      configuration: FKIconViewConfiguration = FKIconViewDefaults.configuration,
      symbolName: String? = nil,
      image: UIImage? = nil,
      tintColor: UIColor? = nil
    ) {
      self.configuration = configuration
      self.symbolName = symbolName
      self.image = image
      self.tintColor = tintColor
    }

    public func makeUIView(context: Context) -> FKIconView {
      let view = FKIconView(configuration: configuration, symbolName: symbolName, image: image)
      view.iconTintColor = tintColor
      return view
    }

    public func updateUIView(_ uiView: FKIconView, context: Context) {
      uiView.configuration = configuration
      uiView.symbolName = symbolName
      uiView.image = image
      uiView.iconTintColor = tintColor
    }
  }
#endif
