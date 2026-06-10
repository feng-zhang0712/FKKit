#if canImport(SwiftUI)
  import SwiftUI
  import UIKit

  /// SwiftUI wrapper around ``FKChipGroup`` with selection binding.
  public struct FKChipGroupRepresentable: UIViewRepresentable {
    public var configuration: FKChipGroupConfiguration
    public var chips: [FKChipItem]
    public var selectionMode: FKChipGroupSelectionMode
    @Binding public var selectedIDs: Set<String>
    public var onSelectionLimitReached: (() -> Void)?
    public var onChipPrimaryAction: ((String) -> Void)?
    public var onChipRemoved: ((String) -> Void)?

    public init(
      configuration: FKChipGroupConfiguration = FKChipGroupDefaults.configuration,
      chips: [FKChipItem],
      selectionMode: FKChipGroupSelectionMode = .multiple(max: nil),
      selectedIDs: Binding<Set<String>>,
      onSelectionLimitReached: (() -> Void)? = nil,
      onChipPrimaryAction: ((String) -> Void)? = nil,
      onChipRemoved: ((String) -> Void)? = nil
    ) {
      self.configuration = configuration
      self.chips = chips
      self.selectionMode = selectionMode
      self._selectedIDs = selectedIDs
      self.onSelectionLimitReached = onSelectionLimitReached
      self.onChipPrimaryAction = onChipPrimaryAction
      self.onChipRemoved = onChipRemoved
    }

    public func makeCoordinator() -> Coordinator {
      Coordinator(selectedIDs: $selectedIDs)
    }

    public func makeUIView(context: Context) -> FKChipGroup {
      let group = FKChipGroup(configuration: configuration, chips: chips, selectionMode: selectionMode)
      group.setSelectedIDs(selectedIDs, animated: false)
      group.onSelectionChange = { ids in
        context.coordinator.selectedIDs.wrappedValue = ids
      }
      group.onSelectionLimitReached = onSelectionLimitReached
      group.onChipPrimaryAction = onChipPrimaryAction
      group.onChipRemoved = onChipRemoved
      return group
    }

    public func updateUIView(_ uiView: FKChipGroup, context: Context) {
      uiView.configuration = configuration
      uiView.selectionMode = selectionMode
      uiView.chips = chips
      uiView.onSelectionChange = { ids in
        context.coordinator.selectedIDs.wrappedValue = ids
      }
      uiView.onSelectionLimitReached = onSelectionLimitReached
      uiView.onChipPrimaryAction = onChipPrimaryAction
      uiView.onChipRemoved = onChipRemoved
      if uiView.selectedIDs != selectedIDs {
        uiView.setSelectedIDs(selectedIDs, animated: true)
      }
    }

    public final class Coordinator {
      var selectedIDs: Binding<Set<String>>
      init(selectedIDs: Binding<Set<String>>) {
        self.selectedIDs = selectedIDs
      }
    }
  }
#endif
