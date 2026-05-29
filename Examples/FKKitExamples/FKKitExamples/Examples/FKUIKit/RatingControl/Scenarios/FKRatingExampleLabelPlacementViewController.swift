import FKUIKit
import UIKit

/// Trailing, bottom, and custom caption configurations.
final class FKRatingExampleLabelPlacementViewController: FKRatingExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Value caption"

    let trailing = makeRating { config in
      config.layout.labelPlacement = .trailing
      config.label.valueSuffix = " / 5"
    }

    let bottom = makeRating { config in
      config.layout.labelPlacement = .bottom
      config.label.valuePrefix = "Score: "
    }

    let custom = makeRating { config in
      config.layout.labelPlacement = .trailing
      config.label.customText = "Highly satisfied"
    }

    [
      ("Trailing numeric", "Shows the snapped value to the right of the icon row.", trailing),
      ("Bottom numeric", "Caption below the icons for stacked form layouts.", bottom),
      ("Custom copy", "`label.customText` overrides numeric formatting.", custom),
    ].forEach { title, caption, rating in
      let box = FKRatingExampleSupport.sectionContainer(title: title)
      box.addArrangedSubview(FKRatingExampleSupport.caption(caption))
      box.addArrangedSubview(FKRatingExampleSupport.embedRating(rating, alignment: .center))
      contentStack.addArrangedSubview(box)
    }
  }

  private func makeRating(mutator: (inout FKRatingConfiguration) -> Void) -> FKRatingControl {
    var configuration = FKRatingDefaults.configuration
    configuration.interaction.mode = .interactive
    configuration.interaction.step = .half
    mutator(&configuration)
    return FKRatingControl(configuration: configuration, value: 3.5, maximumValue: 5)
  }
}
