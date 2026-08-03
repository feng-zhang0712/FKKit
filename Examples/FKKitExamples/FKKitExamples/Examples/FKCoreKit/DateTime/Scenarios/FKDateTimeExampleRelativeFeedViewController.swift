import FKCoreKit
import UIKit

/// WeChat Moments / feed-style ``FKDateTimeRelativeStyle.feed`` buckets.
final class FKDateTimeExampleRelativeFeedViewController: FKDateTimeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Relative · Feed"

    addSection(
      title: "FKDateTimeRelativeStyle.feed",
      note: "Just now → minutes → hours (same day) → yesterday → MM-dd / yyyy-MM-dd. Future values fall back to .standard phrasing."
    )
    addActionButton("Run all feed buckets vs now") { [weak self] in
      guard let self else { return }
      let reference = Date()
      let now = FKDateTime(reference)
      let samples: [(String, FKDateTime)] = [
        ("just now (−10s)", FKDateTime(reference.addingTimeInterval(-10))),
        ("minutes (−12m)", FKDateTimeExampleSupport.offset(from: now, minutes: -12)),
        ("hours same day (−3h)", FKDateTimeExampleSupport.offset(from: now, hours: -3)),
        ("yesterday", FKDateTimeExampleSupport.offset(from: now, days: -1)),
        ("same year (−40d)", FKDateTimeExampleSupport.offset(from: now, days: -40)),
        ("previous year", FKDateTimeExampleSupport.offset(from: now, years: -1)),
        ("future (+2h, uses standard)", FKDateTimeExampleSupport.offset(from: now, hours: 2)),
      ]
      self.appendOutput("reference → \(now.format(.dateTime))")
      for (label, sample) in samples {
        let text = sample.relative(style: .feed, reference: reference)
        self.appendOutput("\(label): \(sample.format(.dateTime)) → \"\(text)\"")
      }
    }

    addClearButton()
    appendOutput("Feed relative demo ready.")
  }
}
