import FKUIKit
import UIKit

/// Forced RTL layout and custom VoiceOver label / hint / value format.
final class FKRatingExampleEnvironmentViewController: FKRatingExampleScrollViewController {

  private let rating = FKRatingControl.interactiveStars(value: 3, step: .half)
  private let rtlSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL & a11y"

    rating.configuration.accessibility.customLabel = "Course rating"
    rating.configuration.accessibility.customHint = "Swipe up or down to adjust"
    rating.configuration.accessibility.valueFormat = "%@ of %@ stars"

    rtlSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let forceRTL = self.rtlSwitch.isOn
      self.rating.semanticContentAttribute = forceRTL ? .forceRightToLeft : .unspecified
      self.view.semanticContentAttribute = forceRTL ? .forceRightToLeft : .unspecified
    }, for: .valueChanged)

    let box = FKRatingExampleSupport.sectionContainer(title: "Accessibility copy")
    box.addArrangedSubview(FKRatingExampleSupport.caption("Custom label, hint, and value format feed VoiceOver. Interactive controls expose the adjustable trait."))
    box.addArrangedSubview(FKRatingExampleSupport.embedRating(rating, alignment: .center))
    box.addArrangedSubview(FKRatingExampleSupport.labeledRow(title: "Force RTL", control: rtlSwitch))
    contentStack.addArrangedSubview(box)
  }
}
