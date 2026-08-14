#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKCheckbox``.
public struct FKCheckboxRepresentable: UIViewRepresentable {
  @Binding public var checkState: FKCheckboxState
  public var configuration: FKCheckboxConfiguration
  public var content: FKCheckboxContentConfiguration
  public var showsError: Bool
  public var animateChanges: Bool
  public var onStateChanged: ((FKCheckboxState) -> Void)?
  public var onLinkActivated: ((URL) -> Void)?

  public init(
    checkState: Binding<FKCheckboxState>,
    configuration: FKCheckboxConfiguration = FKSelectionControlDefaults.checkbox,
    content: FKCheckboxContentConfiguration = .init(),
    showsError: Bool = false,
    animateChanges: Bool = true,
    onStateChanged: ((FKCheckboxState) -> Void)? = nil,
    onLinkActivated: ((URL) -> Void)? = nil
  ) {
    _checkState = checkState
    self.configuration = configuration
    self.content = content
    self.showsError = showsError
    self.animateChanges = animateChanges
    self.onStateChanged = onStateChanged
    self.onLinkActivated = onLinkActivated
  }

  @MainActor
  public final class Coordinator: NSObject {
    var onStateChanged: ((FKCheckboxState) -> Void)?
    var bindingSetter: ((FKCheckboxState) -> Void)?

    @objc func handleValueChanged(_ sender: FKCheckbox) {
      bindingSetter?(sender.checkState)
      onStateChanged?(sender.checkState)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  public func makeUIView(context: Context) -> FKCheckbox {
    let control = FKCheckbox(configuration: configuration, content: content)
    control.setCheckState(checkState, animated: false, sendActions: false)
    control.showsError = showsError
    control.onLinkActivated = onLinkActivated
    context.coordinator.bindingSetter = { checkState = $0 }
    context.coordinator.onStateChanged = onStateChanged
    control.addTarget(context.coordinator, action: #selector(Coordinator.handleValueChanged(_:)), for: .valueChanged)
    return control
  }

  public func updateUIView(_ uiView: FKCheckbox, context: Context) {
    context.coordinator.bindingSetter = { checkState = $0 }
    context.coordinator.onStateChanged = onStateChanged
    uiView.onLinkActivated = onLinkActivated
    uiView.configuration = configuration
    uiView.content = content
    uiView.showsError = showsError
    if uiView.checkState != checkState {
      uiView.setCheckState(checkState, animated: animateChanges, sendActions: false)
    }
  }
}
#endif
