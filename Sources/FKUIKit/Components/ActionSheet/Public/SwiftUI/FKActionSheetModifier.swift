#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// Presents an action sheet when `isPresented` becomes `true`.
@MainActor
public struct FKActionSheetModifier: ViewModifier {
  @Binding private var isPresented: Bool
  private let configuration: FKActionSheetConfiguration
  private let popoverSourceView: UIView?
  private let popoverSourceRect: CGRect?
  private let onDismiss: ((FKActionSheetDismissReason) -> Void)?
  private let onPresentFailure: ((Error) -> Void)?

  /// Creates a modifier that presents an action sheet.
  public init(
    isPresented: Binding<Bool>,
    configuration: FKActionSheetConfiguration,
    popoverSourceView: UIView? = nil,
    popoverSourceRect: CGRect? = nil,
    onDismiss: ((FKActionSheetDismissReason) -> Void)? = nil,
    onPresentFailure: ((Error) -> Void)? = nil
  ) {
    self._isPresented = isPresented
    self.configuration = configuration
    self.popoverSourceView = popoverSourceView
    self.popoverSourceRect = popoverSourceRect
    self.onDismiss = onDismiss
    self.onPresentFailure = onPresentFailure
  }

  public func body(content: Content) -> some View {
    content.background(
      FKActionSheetPresenterRepresentable(
        isPresented: $isPresented,
        configuration: configuration,
        popoverSourceView: popoverSourceView,
        popoverSourceRect: popoverSourceRect,
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
  let popoverSourceView: UIView?
  let popoverSourceRect: CGRect?
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
      if let sheet = context.coordinator.sheet, sheet.isPresented {
        sheet.reload(configuration: configurationForPresentation(coordinator: context.coordinator))
        return
      }
      guard context.coordinator.sheet == nil else { return }
      do {
        let sheet = try FKActionSheet(configuration: configurationForPresentation(coordinator: context.coordinator))
        if let popoverSourceView {
          try sheet.present(
            from: uiViewController,
            anchoredTo: popoverSourceView,
            sourceRect: popoverSourceRect
          )
        } else {
          try sheet.present(from: uiViewController)
        }
        context.coordinator.sheet = sheet
      } catch {
        context.coordinator.sheet = nil
        let failure = error
        let reportFailure = onPresentFailure
        schedulePresentationBindingUpdate {
          isPresented = false
          reportFailure?(failure)
        }
      }
    } else if let sheet = context.coordinator.sheet, sheet.isPresented {
      sheet.dismiss(reason: .programmatic, animated: true)
      context.coordinator.sheet = nil
    } else {
      context.coordinator.sheet = nil
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  private func configurationForPresentation(coordinator: Coordinator) -> FKActionSheetConfiguration {
    var config = configuration
    let priorDidDismiss = config.hooks.didDismiss
    let reportDismiss = onDismiss
    config.hooks.didDismiss = { reason in
      schedulePresentationBindingUpdate {
        priorDidDismiss?(reason)
        coordinator.sheet = nil
        isPresented = false
        reportDismiss?(reason)
      }
    }
    return config
  }

  /// Defers binding and callback updates so SwiftUI is not mutated during `body` / `updateUIViewController`.
  private func schedulePresentationBindingUpdate(_ update: @escaping @MainActor () -> Void) {
    Task { @MainActor in
      update()
    }
  }

  final class Coordinator {
    var sheet: FKActionSheet?
  }
}

public extension View {
  /// Presents an action sheet bound to `isPresented`.
  func fkActionSheet(
    isPresented: Binding<Bool>,
    configuration: FKActionSheetConfiguration,
    popoverSourceView: UIView? = nil,
    popoverSourceRect: CGRect? = nil,
    onDismiss: ((FKActionSheetDismissReason) -> Void)? = nil,
    onPresentFailure: ((Error) -> Void)? = nil
  ) -> some View {
    modifier(
      FKActionSheetModifier(
        isPresented: isPresented,
        configuration: configuration,
        popoverSourceView: popoverSourceView,
        popoverSourceRect: popoverSourceRect,
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
    cancelTitle: String? = FKUIKitI18n.string("fkuikit.common.cancel"),
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
      onDismiss: onDismiss,
      onPresentFailure: onPresentFailure
    )
  }
}
#endif
