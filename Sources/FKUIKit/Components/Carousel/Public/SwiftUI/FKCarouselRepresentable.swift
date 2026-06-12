#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKCarousel``.
public struct FKCarouselRepresentable: UIViewRepresentable {
  @Binding public var currentPage: Int
  public var items: [FKCarouselItem]
  public var configuration: FKCarouselConfiguration
  public var callbacks: FKCarouselCallbacks
  public var pageProvider: ((FKCarouselItem, CGRect) -> UIView)?

  public init(
    items: [FKCarouselItem],
    currentPage: Binding<Int>,
    configuration: FKCarouselConfiguration = FKCarouselDefaults.configuration,
    callbacks: FKCarouselCallbacks = .init(),
    pageProvider: ((FKCarouselItem, CGRect) -> UIView)? = nil
  ) {
    self.items = items
    _currentPage = currentPage
    self.configuration = configuration
    self.callbacks = callbacks
    self.pageProvider = pageProvider
  }

  @MainActor
  public final class Coordinator: NSObject, FKCarouselDelegate {
    var parent: FKCarouselRepresentable

    init(parent: FKCarouselRepresentable) {
      self.parent = parent
    }

    public func carousel(_ carousel: FKCarousel, didScrollToPage index: Int, reason: FKCarouselPageChangeReason) {
      if parent.currentPage != index {
        parent.currentPage = index
      }
      parent.callbacks.onPageChanged?(index, reason)
    }

    public func carousel(_ carousel: FKCarousel, didSelectPageAt index: Int) {
      parent.callbacks.onPageSelected?(index)
    }

    public func carousel(_ carousel: FKCarousel, willAutoAdvanceFrom from: Int, to: Int) -> Bool {
      parent.callbacks.onWillAutoAdvance?(from, to) ?? true
    }

    public func carouselDidEndDragging(_ carousel: FKCarousel, willDecelerate: Bool) {
      parent.callbacks.onDidEndDragging?(willDecelerate)
    }

    public func carousel(_ carousel: FKCarousel, didUpdateScrollProgress progress: CGFloat, fromPage: Int, toPage: Int) {
      parent.callbacks.onScrollProgress?(progress, fromPage, toPage)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  public func makeUIView(context: Context) -> FKCarousel {
    let carousel = FKCarousel(configuration: configuration, items: items)
    carousel.pageProvider = pageProvider
    carousel.delegate = context.coordinator
    return carousel
  }

  public func updateUIView(_ uiView: FKCarousel, context: Context) {
    context.coordinator.parent = self
    uiView.configuration = configuration
    uiView.pageProvider = pageProvider
    if uiView.items != items {
      uiView.setItems(items, animated: false, preservingIndex: true)
    }
    if uiView.currentPageIndex != currentPage {
      uiView.scrollToPage(currentPage, animated: false)
    }
  }
}
#endif
