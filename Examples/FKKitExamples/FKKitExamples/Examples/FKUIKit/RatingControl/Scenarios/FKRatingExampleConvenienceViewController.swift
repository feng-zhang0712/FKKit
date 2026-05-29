import FKUIKit
import UIKit

/// `FKRatingControl.readOnlyStars` and `interactiveStars` factory helpers.
final class FKRatingExampleConvenienceViewController: FKRatingExampleScrollViewController {

  private let interactive = FKRatingControl.interactiveStars(value: 0, step: .whole)
  private let readOnly = FKRatingControl.readOnlyStars(value: 4, itemCount: 5)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Factories"

    let interactiveBox = FKRatingExampleSupport.sectionContainer(title: "interactiveStars(step: .whole)")
    interactiveBox.addArrangedSubview(FKRatingExampleSupport.caption("Starts at zero — user must pick a score before submitting feedback."))
    interactiveBox.addArrangedSubview(FKRatingExampleSupport.embedRating(interactive))
    contentStack.addArrangedSubview(interactiveBox)

    let readOnlyBox = FKRatingExampleSupport.sectionContainer(title: "readOnlyStars(value: 4)")
    readOnlyBox.addArrangedSubview(FKRatingExampleSupport.caption("Ignores touch; uses `.readOnly` interaction mode under the hood."))
    readOnlyBox.addArrangedSubview(FKRatingExampleSupport.embedRating(readOnly))
    contentStack.addArrangedSubview(readOnlyBox)
  }
}
