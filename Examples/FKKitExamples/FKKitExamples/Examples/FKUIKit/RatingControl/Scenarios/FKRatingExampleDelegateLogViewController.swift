import FKUIKit
import UIKit

/// ``FKRatingControlDelegate`` and closure callbacks with a timestamped log.
final class FKRatingExampleDelegateLogViewController: FKRatingExampleScrollViewController, FKRatingControlDelegate {

  private let rating = FKRatingControl.interactiveStars(value: 2, step: .half)
  private let logView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Delegate log"

    rating.delegate = self
    rating.onValueChanged = { [weak self] value in
      self?.appendLog("onValueChanged → \(value)")
    }

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    logView.backgroundColor = .tertiarySystemGroupedBackground
    logView.layer.cornerRadius = 8
    logView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    logView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true

    let box = FKRatingExampleSupport.sectionContainer(title: "Change the rating")
    box.addArrangedSubview(FKRatingExampleSupport.caption("Delegate methods and the closure both append to the log below."))
    box.addArrangedSubview(FKRatingExampleSupport.embedRating(rating))
    box.addArrangedSubview(logView)
    contentStack.addArrangedSubview(box)
  }

  func ratingControl(_ control: FKRatingControl, willChangeValue to: Double) {
    appendLog("willChangeValue → \(to)")
  }

  func ratingControl(_ control: FKRatingControl, didChangeValue to: Double) {
    appendLog("didChangeValue → \(to)")
  }

  private func appendLog(_ line: String) {
    let stamp = Self.timeFormatter.string(from: Date())
    let entry = "[\(stamp)] \(line)\n"
    logView.text = (logView.text ?? "") + entry
    let end = NSRange(location: max(0, (logView.text as NSString).length - 1), length: 1)
    logView.scrollRangeToVisible(end)
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()
}
