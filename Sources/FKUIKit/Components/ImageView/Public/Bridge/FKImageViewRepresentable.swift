#if canImport(SwiftUI)
  import FKCoreKit
  import SwiftUI
  import UIKit

  /// SwiftUI wrapper around ``FKImageView``.
  public struct FKImageViewRepresentable: UIViewRepresentable {
    public var url: URL?
    public var configuration: FKImageViewConfiguration
    public var imageLoader: (any FKImageLoading)?
    public var cacheKey: String?
    public var onStateChange: ((FKImageViewState) -> Void)?
    public var onTap: (() -> Void)?

    public init(
      url: URL?,
      configuration: FKImageViewConfiguration = FKImageViewDefaults.defaultConfiguration,
      imageLoader: (any FKImageLoading)? = nil,
      cacheKey: String? = nil,
      onStateChange: ((FKImageViewState) -> Void)? = nil,
      onTap: (() -> Void)? = nil
    ) {
      self.url = url
      self.configuration = configuration
      self.imageLoader = imageLoader
      self.cacheKey = cacheKey
      self.onStateChange = onStateChange
      self.onTap = onTap
    }

    public func makeUIView(context: Context) -> FKImageView {
      let view = FKImageView(configuration: configuration)
      view.imageLoader = imageLoader
      view.cacheKey = cacheKey
      view.onStateChange = onStateChange
      view.onTap = onTap
      view.load(url: url)
      return view
    }

    public func updateUIView(_ uiView: FKImageView, context: Context) {
      uiView.configuration = configuration
      uiView.imageLoader = imageLoader
      uiView.cacheKey = cacheKey
      uiView.onStateChange = onStateChange
      uiView.onTap = onTap
      if uiView.url != url {
        uiView.load(url: url)
      }
    }
  }
#endif
