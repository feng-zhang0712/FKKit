#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// Presents an action sheet when `isPresented` becomes `true`.
@MainActor
public struct FKActionSheetModifier: ViewModifier {
  @Binding private var isPresented: Bool
  private let configuration: FKActionSheetConfiguration
  private let hostContext: FKActionSheetPresentationHostContext
  private let onDismiss: ((FKActionSheetDismissReason) -> Void)?
  private let onPresentFailure: ((Error) -> Void)?

  /// Creates a modifier that presents an action sheet.
  public init(
    isPresented: Binding<Bool>,
    configuration: FKActionSheetConfiguration,
    hostContext: FKActionSheetPresentationHostContext = .init(),
    onDismiss: ((FKActionSheetDismissReason) -> Void)? = nil,
    onPresentFailure: ((Error) -> Void)? = nil
  ) {
    self._isPresented = isPresented
    self.configuration = configuration
    self.hostContext = hostContext
    self.onDismiss = onDismiss
    self.onPresentFailure = onPresentFailure
  }

  public func body(content: Content) -> some View {
    content.background(
      FKActionSheetPresenterRepresentable(
        isPresented: $isPresented,
        configuration: configuration,
        hostContext: hostContext,
        onDismiss: onDismiss,
        onPresentFailure: onPresentFailure
      )
      .frame(width: 0, height: 0)
    )
  }
}

@MainActor
private struct FKActionSheetPresenterRepresentable: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  let configuration: FKActionSheetConfiguration
  let hostContext: FKActionSheetPresentationHostContext
  let onDismiss: ((FKActionSheetDismissReason) -> Void)?
  let onPresentFailure: ((Error) -> Void)?

  func makeUIViewController(context: Context) -> UIViewController {
    let controller = UIViewController()
    controller.view.isUserInteractionEnabled = false
    controller.view.backgroundColor = .clear
    return controller
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    if isPresented {
      if let handle = context.coordinator.handle, handle.isPresented {
        handle.reload(configuration: configurationForPresentation(coordinator: context.coordinator))
        return
      }
      guard context.coordinator.handle == nil else { return }
      do {
        let handle = try FKActionSheet.present(
          configuration: configurationForPresentation(coordinator: context.coordinator),
          hostContext: hostContext.mergingFallbackPresenter(uiViewController)
        )
        context.coordinator.handle = handle
      } catch {
        context.coordinator.handle = nil
        isPresented = false
        onPresentFailure?(error)
      }
    } else if let handle = context.coordinator.handle, handle.isPresented {
      handle.dismiss(reason: .programmatic, animated: true)
      context.coordinator.handle = nil
    } else {
      context.coordinator.handle = nil
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  private func configurationForPresentation(coordinator: Coordinator) -> FKActionSheetConfiguration {
    var config = configuration
    let priorDidDismiss = config.hooks.didDismiss
    config.hooks.didDismiss = { reason in
      priorDidDismiss?(reason)
      coordinator.handle = nil
      isPresented = false
      onDismiss?(reason)
    }
    return config
  }

  final class Coordinator {
    var handle: FKActionSheetHandle?
  }
}

private extension FKActionSheetPresentationHostContext {
  func mergingFallbackPresenter(_ fallback: UIViewController) -> FKActionSheetPresentationHostContext {
    if presenter?.object != nil { return self }
    var copy = self
    copy.presenter = FKWeakReference(fallback)
    return copy
  }
}

public extension View {
  /// Presents an action sheet bound to `isPresented`.
  func fkActionSheet(
    isPresented: Binding<Bool>,
    configuration: FKActionSheetConfiguration,
    hostContext: FKActionSheetPresentationHostContext = .init(),
    onDismiss: ((FKActionSheetDismissReason) -> Void)? = nil,
    onPresentFailure: ((Error) -> Void)? = nil
  ) -> some View {
    modifier(
      FKActionSheetModifier(
        isPresented: isPresented,
        configuration: configuration,
        hostContext: hostContext,
        onDismiss: onDismiss,
        onPresentFailure: onPresentFailure
      )
    )
  }

  /// Presents an action sheet built from alert-style parameters.
  func fkActionSheet(
    isPresented: Binding<Bool>,
    title: String?,
    message: String? = nil,
    actions: [FKActionSheetAction],
    cancelTitle: String? = "Cancel",
    hostContext: FKActionSheetPresentationHostContext = .init(),
    onDismiss: ((FKActionSheetDismissReason) -> Void)? = nil,
    onPresentFailure: ((Error) -> Void)? = nil
  ) -> some View {
    fkActionSheet(
      isPresented: isPresented,
      configuration: FKActionSheetConfiguration(
        alertTitle: title,
        message: message,
        actions: actions,
        cancelTitle: cancelTitle
      ),
      hostContext: hostContext,
      onDismiss: onDismiss,
      onPresentFailure: onPresentFailure
    )
  }
}
#endif
