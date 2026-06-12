#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKImageBanner``.
public struct FKImageBannerRepresentable: UIViewRepresentable {
  @Binding public var currentPage: Int
  public var slides: [FKImageBannerSlide]
  public var configuration: FKImageBannerConfiguration
  public var callbacks: FKImageBannerCallbacks

  public init(
    slides: [FKImageBannerSlide],
    currentPage: Binding<Int>,
    configuration: FKImageBannerConfiguration = FKCarouselDefaults.imageBannerConfiguration,
    callbacks: FKImageBannerCallbacks = .init()
  ) {
    self.slides = slides
    _currentPage = currentPage
    self.configuration = configuration
    self.callbacks = callbacks
  }

  @MainActor
  public final class Coordinator: NSObject, FKImageBannerDelegate {
    var parent: FKImageBannerRepresentable

    init(parent: FKImageBannerRepresentable) {
      self.parent = parent
    }

    public func imageBanner(_ banner: FKImageBanner, didScrollToSlide index: Int, reason: FKCarouselPageChangeReason) {
      if parent.currentPage != index {
        parent.currentPage = index
      }
      parent.callbacks.onSlideChanged?(index, reason)
    }

    public func imageBanner(_ banner: FKImageBanner, didSelectSlideAt index: Int) {
      parent.callbacks.onSlideTap?(index)
    }

    public func imageBanner(_ banner: FKImageBanner, shouldOpenLink url: URL, forSlideAt index: Int) -> Bool {
      parent.callbacks.onShouldOpenLink?(url, index) ?? true
    }

    public func imageBanner(_ banner: FKImageBanner, didTapCTAForSlideAt index: Int) {
      parent.callbacks.onCTATap?(index)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  public func makeUIView(context: Context) -> FKImageBanner {
    let banner = FKImageBanner(configuration: configuration, slides: slides)
    banner.delegate = context.coordinator
    return banner
  }

  public func updateUIView(_ uiView: FKImageBanner, context: Context) {
    context.coordinator.parent = self
    uiView.configuration = configuration
    if uiView.slides != slides {
      uiView.setSlides(slides, preservingIndex: true)
    }
    if uiView.currentSlideIndex != currentPage {
      uiView.scrollToSlide(currentPage, animated: false)
    }
  }
}
#endif
