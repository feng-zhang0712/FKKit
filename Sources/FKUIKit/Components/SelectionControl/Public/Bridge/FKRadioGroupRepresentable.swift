#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKRadioGroup``.
public struct FKRadioGroupRepresentable: UIViewRepresentable {
  @Binding public var selectedOptionID: FKRadioOptionID?
  public var configuration: FKRadioGroupConfiguration
  public var options: [FKRadioOption]
  public var headerTitle: String?
  public var footerTitle: String?
  public var showsError: Bool
  public var animateChanges: Bool
  public var onSelectionChanged: ((FKRadioOptionID?) -> Void)?

  public init(
    selectedOptionID: Binding<FKRadioOptionID?>,
    options: [FKRadioOption],
    configuration: FKRadioGroupConfiguration = FKSelectionControlDefaults.radioGroup,
    headerTitle: String? = nil,
    footerTitle: String? = nil,
    showsError: Bool = false,
    animateChanges: Bool = true,
    onSelectionChanged: ((FKRadioOptionID?) -> Void)? = nil
  ) {
    _selectedOptionID = selectedOptionID
    self.options = options
    self.configuration = configuration
    self.headerTitle = headerTitle
    self.footerTitle = footerTitle
    self.showsError = showsError
    self.animateChanges = animateChanges
    self.onSelectionChanged = onSelectionChanged
  }

  @MainActor
  public final class Coordinator: NSObject {
    var onSelectionChanged: ((FKRadioOptionID?) -> Void)?
    var bindingSetter: ((FKRadioOptionID?) -> Void)?

    @objc func handleValueChanged(_ sender: FKRadioGroup) {
      bindingSetter?(sender.selectedOptionID)
      onSelectionChanged?(sender.selectedOptionID)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  public func makeUIView(context: Context) -> FKRadioGroup {
    let control = FKRadioGroup(configuration: configuration, options: options)
    control.headerTitle = headerTitle
    control.footerTitle = footerTitle
    control.showsError = showsError
    control.setSelectedOptionID(selectedOptionID, animated: false, sendActions: false)
    context.coordinator.bindingSetter = { selectedOptionID = $0 }
    context.coordinator.onSelectionChanged = onSelectionChanged
    control.addTarget(context.coordinator, action: #selector(Coordinator.handleValueChanged(_:)), for: .valueChanged)
    return control
  }

  public func updateUIView(_ uiView: FKRadioGroup, context: Context) {
    context.coordinator.bindingSetter = { selectedOptionID = $0 }
    context.coordinator.onSelectionChanged = onSelectionChanged
    uiView.configuration = configuration
    uiView.options = options
    uiView.headerTitle = headerTitle
    uiView.footerTitle = footerTitle
    uiView.showsError = showsError
    if uiView.selectedOptionID != selectedOptionID {
      uiView.setSelectedOptionID(selectedOptionID, animated: animateChanges, sendActions: false)
    }
  }
}
#endif
