import FKUIKit
import UIKit

/// Disabled state, tap-only selection, haptics, and selection animation.
final class FKRatingExampleInteractionModesViewController: FKRatingExampleScrollViewController {

  private let disabledRating = FKRatingControl.interactiveStars(value: 2)
  private let tapOnlyRating = FKRatingControl.interactiveStars(value: 4)
  private let hapticRating = FKRatingControl.interactiveStars(value: 1)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Modes & feedback"

    disabledRating.isEnabled = false

    tapOnlyRating.configuration.interaction.allowsDragSelection = false
    tapOnlyRating.configuration.motion.selectionAnimation = .none

    hapticRating.configuration.interaction.touchHaptic = .selection
    hapticRating.configuration.motion.selectionAnimation = .bounce

    let disabledBox = FKRatingExampleSupport.sectionContainer(title: "Disabled")
    disabledBox.addArrangedSubview(FKRatingExampleSupport.caption("`isEnabled = false` applies `disabledAlpha` and blocks interaction."))
    disabledBox.addArrangedSubview(FKRatingExampleSupport.embedRating(disabledRating))
    contentStack.addArrangedSubview(disabledBox)

    let tapBox = FKRatingExampleSupport.sectionContainer(title: "Tap only")
    tapBox.addArrangedSubview(FKRatingExampleSupport.caption("`allowsDragSelection = false` — discrete taps only."))
    tapBox.addArrangedSubview(FKRatingExampleSupport.embedRating(tapOnlyRating))
    contentStack.addArrangedSubview(tapBox)

    let hapticBox = FKRatingExampleSupport.sectionContainer(title: "Selection haptic")
    hapticBox.addArrangedSubview(FKRatingExampleSupport.caption("`touchHaptic = .selection` fires when the snapped value changes."))
    hapticBox.addArrangedSubview(FKRatingExampleSupport.embedRating(hapticRating))
    contentStack.addArrangedSubview(hapticBox)
  }
}
