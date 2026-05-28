import UIKit
import FKUIKit

/// Compares layout-scoped ``FKSheetPresentationConfiguration`` presets and ``applyingSheet(_:)``.
final class ConfigurationPresetsExampleViewController: FKSheetPresentationExamplePageViewController {
  private var presetIndex: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Configuration presets",
      subtitle: "Start from tuned layout presets instead of hand-rolling every field.",
      notes: """
      Presets live on `FKSheetPresentationConfiguration` (for example `bottomSheetDefault`, `centerCard`).
      Use `applyingSheet { … }` when you need to tweak detents on an existing sheet preset.
      """
    )

    addView(
      FKExampleControls.segmented(
        title: "Preset",
        items: ["bottomSheet", "topSheet", "centerCard", "centerAlert", "passthrough"],
        selectedIndex: presetIndex
      ) { [weak self] idx in
        self?.presetIndex = idx
      }
    )

    addPrimaryButton(title: "Present preset") { [weak self] in
      guard let self else { return }
      var configuration = self.selectedPreset()
      _ = configuration.applyingSheet { sheet in
        sheet.detents = [.fitContent, .medium, .full]
      }
      _ = FKSheetPresentationExampleHelpers.present(
        from: self,
        title: "Preset demo",
        configuration: configuration
      )
    }
  }

  private func selectedPreset() -> FKSheetPresentationConfiguration {
    switch presetIndex {
    case 1: return .topSheetDefault
    case 2: return .centerCard
    case 3: return .centerAlert
    case 4: return .passthroughOverlay
    default: return .bottomSheetDefault
    }
  }
}
