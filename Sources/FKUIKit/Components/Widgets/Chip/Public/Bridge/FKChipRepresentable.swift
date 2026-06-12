#if canImport(SwiftUI)
  import SwiftUI
  import UIKit

  /// SwiftUI wrapper around ``FKChip`` with optional selection binding.
  public struct FKChipRepresentable: UIViewRepresentable {
    public var configuration: FKChipConfiguration
    public var mode: FKChipMode
    public var title: String
    @Binding public var isSelected: Bool
    public var leadingIcon: FKChipIcon?
    public var showsRemoveButton: Bool
    public var onRemove: (() -> Void)?

    public init(
      configuration: FKChipConfiguration = FKChipDefaults.configuration,
      mode: FKChipMode = .filter,
      title: String,
      isSelected: Binding<Bool>,
      leadingIcon: FKChipIcon? = nil,
      showsRemoveButton: Bool = false,
      onRemove: (() -> Void)? = nil
    ) {
      self.configuration = configuration
      self.mode = mode
      self.title = title
      self._isSelected = isSelected
      self.leadingIcon = leadingIcon
      self.showsRemoveButton = showsRemoveButton
      self.onRemove = onRemove
    }

    public func makeCoordinator() -> Coordinator {
      Coordinator(isSelected: $isSelected)
    }

    public func makeUIView(context: Context) -> FKChip {
      let chip = FKChip(configuration: configuration, mode: mode, title: title)
      chip.leadingIcon = leadingIcon
      chip.showsRemoveButton = showsRemoveButton
      chip.onRemove = onRemove
      chip.isSelected = isSelected
      chip.addAction(UIAction { [weak chip] _ in
        guard let chip else { return }
        context.coordinator.isSelected.wrappedValue = chip.isSelected
      }, for: .valueChanged)
      return chip
    }

    public func updateUIView(_ uiView: FKChip, context: Context) {
      uiView.configuration = configuration
      uiView.mode = mode
      uiView.title = title
      uiView.leadingIcon = leadingIcon
      uiView.showsRemoveButton = showsRemoveButton
      uiView.onRemove = onRemove
      if uiView.isSelected != isSelected {
        uiView.isSelected = isSelected
      }
    }

    public final class Coordinator {
      var isSelected: Binding<Bool>
      init(isSelected: Binding<Bool>) {
        self.isSelected = isSelected
      }
    }
  }
#endif
