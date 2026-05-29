import FKUIKit
import UIKit

/// Side-by-side ``FKRatingIconPreset`` styles.
final class FKRatingExampleIconPresetsViewController: FKRatingExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Icon presets"

    contentStack.addArrangedSubview(makePresetCard(
      title: "Stars",
      caption: "Default commerce style with system yellow fill.",
      preset: .star,
      filledColor: .systemYellow,
      value: 4
    ))

    contentStack.addArrangedSubview(makePresetCard(
      title: "Hearts",
      caption: "Favorites / wishlist feedback.",
      preset: .heart,
      filledColor: .systemPink,
      value: 3
    ))

    contentStack.addArrangedSubview(makePresetCard(
      title: "Thumb up",
      caption: "Binary-ish helpfulness prompts.",
      preset: .thumbUp,
      filledColor: .systemBlue,
      value: 1
    ))
  }

  private func makePresetCard(
    title: String,
    caption: String,
    preset: FKRatingIconPreset,
    filledColor: UIColor,
    value: Double
  ) -> UIStackView {
    var configuration = FKRatingDefaults.configuration
    configuration.interaction.mode = .interactive
    configuration.appearance.iconStyle = .preset(preset)
    configuration.appearance.filledColor = filledColor

    let rating = FKRatingControl(configuration: configuration, value: value, maximumValue: 5)

    let box = FKRatingExampleSupport.sectionContainer(title: title)
    box.addArrangedSubview(FKRatingExampleSupport.caption(caption))
    box.addArrangedSubview(FKRatingExampleSupport.embedRating(rating))
    return box
  }
}
