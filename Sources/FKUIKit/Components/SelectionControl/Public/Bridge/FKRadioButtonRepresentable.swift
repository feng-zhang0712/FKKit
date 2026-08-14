#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKRadioButton``.
public struct FKRadioButtonRepresentable: UIViewRepresentable {
  @Binding public var isSelected: Bool
  public var configuration: FKRadioButtonConfiguration
  public var content: FKRadioButtonContentConfiguration
  public var showsError: Bool
  public var animateChanges: Bool
  public var onSelectionChanged: ((Bool) -> Void)?
  public var onLinkActivated: ((URL) -> Void)?

  public init(
    isSelected: Binding<Bool>,
    configuration: FKRadioButtonConfiguration = FKSelectionControlDefaults.radioButton,
    content: FKRadioButtonContentConfiguration = .init(),
    showsError: Bool = false,
    animateChanges: Bool = true,
    onSelectionChanged: ((Bool) -> Void)? = nil,
    onLinkActivated: ((URL) -> Void)? = nil
  ) {
    _isSelected = isSelected
    self.configuration = configuration
    self.content = content
    self.showsError = showsError
    self.animateChanges = animateChanges
    self.onSelectionChanged = onSelectionChanged
    self.onLinkActivated = onLinkActivated
  }

  @MainActor
  public final class Coordinator: NSObject {
    var onSelectionChanged: ((Bool) -> Void)?
    var bindingSetter: ((Bool) -> Void)?

    @objc func handleValueChanged(_ sender: FKRadioButton) {
      bindingSetter?(sender.isSelected)
      onSelectionChanged?(sender.isSelected)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  public func makeUIView(context: Context) -> FKRadioButton {
    let control = FKRadioButton(configuration: configuration, content: content)
    control.setSelected(isSelected, animated: false, sendActions: false)
    control.showsError = showsError
    control.onLinkActivated = onLinkActivated
    context.coordinator.bindingSetter = { isSelected = $0 }
    context.coordinator.onSelectionChanged = onSelectionChanged
    control.addTarget(context.coordinator, action: #selector(Coordinator.handleValueChanged(_:)), for: .valueChanged)
    return control
  }

  public func updateUIView(_ uiView: FKRadioButton, context: Context) {
    context.coordinator.bindingSetter = { isSelected = $0 }
    context.coordinator.onSelectionChanged = onSelectionChanged
    uiView.onLinkActivated = onLinkActivated
    uiView.configuration = configuration
    uiView.content = content
    uiView.showsError = showsError
    if uiView.isSelected != isSelected {
      uiView.setSelected(isSelected, animated: animateChanges, sendActions: false)
    }
  }
}
#endif
