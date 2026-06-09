#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI button that triggers ``FKPhotoPicker`` from the nearest view-controller presenter.
@MainActor
public struct FKPhotoPickerButton<Label: View>: View {
  private let configuration: FKPhotoPickerConfiguration
  private let popoverAnchor: FKPhotoPickerPopoverAnchor?
  private let progressHandler: FKPhotoPickerProgressHandler?
  private let onCompletion: @MainActor (Result<[FKPhotoPickerResult], FKPhotoPickerError>) -> Void
  private let label: Label

  @StateObject private var presenterHost = FKPhotoPickerPresenterHost()

  /// Creates a button that presents the system picker when tapped.
  public init(
    configuration: FKPhotoPickerConfiguration = FKPhotoPickerDefaults.configuration,
    popoverAnchor: FKPhotoPickerPopoverAnchor? = nil,
    progressHandler: FKPhotoPickerProgressHandler? = nil,
    onCompletion: @escaping @MainActor (Result<[FKPhotoPickerResult], FKPhotoPickerError>) -> Void,
    @ViewBuilder label: () -> Label
  ) {
    self.configuration = configuration
    self.popoverAnchor = popoverAnchor
    self.progressHandler = progressHandler
    self.onCompletion = onCompletion
    self.label = label()
  }

  public var body: some View {
    Button {
      guard let presenter = presenterHost.presenter else {
        onCompletion(.failure(.processingFailed(underlyingDescription: "Presenter view controller not found.")))
        return
      }
      Task { @MainActor in
        let picker = FKPhotoPicker()
        do {
          let results = try await picker.pick(
            from: presenter,
            configuration: configuration,
            popoverAnchor: popoverAnchor,
            progressHandler: progressHandler
          )
          onCompletion(.success(results))
        } catch let error as FKPhotoPickerError {
          onCompletion(.failure(error))
        } catch {
          onCompletion(.failure(.processingFailed(underlyingDescription: error.localizedDescription)))
        }
      }
    } label: {
      label
    }
    .background(
      FKPhotoPickerPresenterRepresentable(host: presenterHost)
        .frame(width: 0, height: 0)
    )
  }
}

@MainActor
private final class FKPhotoPickerPresenterHost: ObservableObject {
  weak var presenter: UIViewController?
}

@MainActor
private struct FKPhotoPickerPresenterRepresentable: UIViewControllerRepresentable {
  let host: FKPhotoPickerPresenterHost

  func makeUIViewController(context: Context) -> UIViewController {
    let controller = UIViewController()
    controller.view.isHidden = true
    controller.view.isUserInteractionEnabled = false
    return controller
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    if let parent = uiViewController.parent {
      host.presenter = parent
    } else {
      DispatchQueue.main.async {
        host.presenter = uiViewController.parent ?? uiViewController
      }
    }
  }
}
#endif
