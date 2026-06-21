#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI bridge that presents ``FKMediaGallery`` when `isPresented` becomes true.
@MainActor
public struct FKMediaGalleryPresenter: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  var items: [FKMediaGalleryItem]
  var startIndex: Int
  var configuration: FKMediaGalleryConfiguration
  var transitionSource: FKMediaGalleryTransitionSource?
  var delegate: FKMediaGalleryDelegate?

  public init(
    isPresented: Binding<Bool>,
    items: [FKMediaGalleryItem],
    startIndex: Int = 0,
    configuration: FKMediaGalleryConfiguration = FKMediaGalleryPresets.socialFeed(),
    transitionSource: FKMediaGalleryTransitionSource? = nil,
    delegate: FKMediaGalleryDelegate? = nil
  ) {
    _isPresented = isPresented
    self.items = items
    self.startIndex = startIndex
    self.configuration = configuration
    self.transitionSource = transitionSource
    self.delegate = delegate
  }

  public func makeUIViewController(context: Context) -> FKMediaGalleryPresenterViewController {
    FKMediaGalleryPresenterViewController()
  }

  public func updateUIViewController(_ uiViewController: FKMediaGalleryPresenterViewController, context: Context) {
    uiViewController.updatePresentation(
      isPresented: isPresented,
      onDismiss: { isPresented = false },
      items: items,
      startIndex: startIndex,
      configuration: configuration,
      transitionSource: transitionSource,
      delegate: delegate
    )
  }
}

@MainActor
public final class FKMediaGalleryPresenterViewController: UIViewController {
  private var gallery: FKMediaGallery?
  private var wasPresented = false

  func updatePresentation(
    isPresented: Bool,
    onDismiss: @escaping () -> Void,
    items: [FKMediaGalleryItem],
    startIndex: Int,
    configuration: FKMediaGalleryConfiguration,
    transitionSource: FKMediaGalleryTransitionSource?,
    delegate: FKMediaGalleryDelegate?
  ) {
    guard isPresented else {
      wasPresented = false
      return
    }
    guard !wasPresented else { return }
    guard let presenter = nearestPresenter() else { return }
    wasPresented = true
    let gallery = FKMediaGallery(configuration: configuration)
    gallery.delegate = delegate
    self.gallery = gallery
    do {
      try gallery.present(
        from: presenter,
        items: items,
        startIndex: startIndex,
        transitionSource: transitionSource,
        configuration: configuration
      )
    } catch {
      wasPresented = false
      onDismiss()
    }
  }

  private func nearestPresenter() -> UIViewController? {
    sequence(first: self.parent, next: { $0?.parent }).compactMap { $0 }.last ?? self
  }
}

public extension View {
  /// Presents ``FKMediaGallery`` when `isPresented` is true.
  func fkMediaGallery(
    isPresented: Binding<Bool>,
    items: [FKMediaGalleryItem],
    startIndex: Int = 0,
    configuration: FKMediaGalleryConfiguration = FKMediaGalleryPresets.socialFeed()
  ) -> some View {
    background(
      FKMediaGalleryPresenter(
        isPresented: isPresented,
        items: items,
        startIndex: startIndex,
        configuration: configuration
      )
      .frame(width: 0, height: 0)
    )
  }
}
#endif
