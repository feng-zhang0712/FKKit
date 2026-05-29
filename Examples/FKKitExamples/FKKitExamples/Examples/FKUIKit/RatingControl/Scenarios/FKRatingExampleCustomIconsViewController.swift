import FKUIKit
import UIKit

/// Custom SF Symbol names and host-provided `UIImage` pairs.
final class FKRatingExampleCustomIconsViewController: FKRatingExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom icons"

    var symbolConfig = FKRatingDefaults.configuration
    symbolConfig.appearance.iconStyle = .symbols(
      empty: "bolt",
      filled: "bolt.fill"
    )
    symbolConfig.appearance.filledColor = .systemOrange
    symbolConfig.appearance.emptyColor = .tertiaryLabel
    let symbolRating = FKRatingControl(configuration: symbolConfig, value: 3)

    let symbolBox = FKRatingExampleSupport.sectionContainer(title: "Custom SF Symbols")
    symbolBox.addArrangedSubview(FKRatingExampleSupport.caption("`.symbols(empty:filled:)` resolves names at runtime."))
    symbolBox.addArrangedSubview(FKRatingExampleSupport.embedRating(symbolRating))
    contentStack.addArrangedSubview(symbolBox)

    let empty = FKRatingExampleSupport.symbolImage(named: "flag") ?? UIImage()
    let filled = FKRatingExampleSupport.symbolImage(named: "flag.fill") ?? UIImage()
    var imageConfig = FKRatingDefaults.configuration
    imageConfig.appearance.iconStyle = .images(empty: empty, filled: filled)
    imageConfig.appearance.filledColor = .systemGreen
    let imageRating = FKRatingControl(configuration: imageConfig, value: 2.5)
    imageRating.configuration.interaction.step = .half

    let imageBox = FKRatingExampleSupport.sectionContainer(title: "Custom UIImages")
    imageBox.addArrangedSubview(FKRatingExampleSupport.caption("`.images(empty:filled:)` for brand assets or pre-rendered glyphs."))
    imageBox.addArrangedSubview(FKRatingExampleSupport.embedRating(imageRating))
    contentStack.addArrangedSubview(imageBox)
  }
}
