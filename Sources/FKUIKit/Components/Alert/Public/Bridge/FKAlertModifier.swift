#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// Presents a centered FK alert when `isPresented` becomes `true`.
@MainActor
public struct FKAlertModifier: ViewModifier {
  @Binding private var isPresented: Bool
  private let content: FKAlertContent
  private let configuration: FKAlertConfiguration
  private let onResult: (FKAlertResult) -> Void

  /// Creates a modifier that presents an alert bound to `isPresented`.
  public init(
    isPresented: Binding<Bool>,
    content: FKAlertContent,
    configuration: FKAlertConfiguration = .init(),
    onResult: @escaping (FKAlertResult) -> Void
  ) {
    self._isPresented = isPresented
    self.content = content
    self.configuration = configuration
    self.onResult = onResult
  }

  public func body(content: Content) -> some View {
    content.background(
      FKAlertPresenterRepresentable(
        isPresented: $isPresented,
        alertContent: self.content,
        configuration: configuration,
        onResult: onResult
      )
      .frame(width: 0, height: 0)
    )
  }
}

@MainActor
private struct FKAlertPresenterRepresentable: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  let alertContent: FKAlertContent
  let configuration: FKAlertConfiguration
  let onResult: (FKAlertResult) -> Void

  func makeUIViewController(context: Context) -> UIViewController {
    let controller = UIViewController()
    controller.view.isUserInteractionEnabled = false
    controller.view.backgroundColor = .clear
    return controller
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    if isPresented {
      guard context.coordinator.task == nil else { return }
      let task = Task { @MainActor in
        let result = await FKAlertPresenter.shared.present(
          alertContent,
          from: uiViewController,
          configuration: configuration
        )
        context.coordinator.task = nil
        guard !Task.isCancelled else { return }
        isPresented = false
        onResult(result)
      }
      context.coordinator.task = task
    } else if let task = context.coordinator.task {
      task.cancel()
      context.coordinator.task = nil
      FKAlertPresenter.shared.dismiss(animated: true)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  final class Coordinator {
    var task: Task<Void, Never>?
  }
}

public extension View {
  /// Presents a centered FK alert when `isPresented` is `true`.
  func fkAlert(
    isPresented: Binding<Bool>,
    content: FKAlertContent,
    configuration: FKAlertConfiguration = .init(),
    onResult: @escaping (FKAlertResult) -> Void
  ) -> some View {
    modifier(
      FKAlertModifier(
        isPresented: isPresented,
        content: content,
        configuration: configuration,
        onResult: onResult
      )
    )
  }
}
#endif
