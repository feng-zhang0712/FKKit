import FKCoreKit
import UIKit

/// WeChat conversation-style ``FKDateTimeRelativeStyle.chat`` buckets.
final class FKDateTimeExampleRelativeChatViewController: FKDateTimeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Relative · Chat"

    addSection(
      title: "FKDateTimeRelativeStyle.chat",
      note: "Same day → HH:mm; yesterday → Yesterday HH:mm; <7 days → weekday + time; same year → MM-dd HH:mm; else full date-time."
    )
    addActionButton("Run all chat buckets vs now") { [weak self] in
      guard let self else { return }
      let reference = Date()
      let now = FKDateTime(reference)
      let samples: [(String, FKDateTime)] = [
        ("same day (−30m)", FKDateTimeExampleSupport.offset(from: now, minutes: -30)),
        ("yesterday", FKDateTimeExampleSupport.offset(from: now, days: -1, hours: -2)),
        ("3 days ago (weekday)", FKDateTimeExampleSupport.offset(from: now, days: -3, hours: -1)),
        ("6 days ago", FKDateTimeExampleSupport.offset(from: now, days: -6)),
        ("same year earlier month", FKDateTimeExampleSupport.offset(from: now, months: -2, days: -1)),
        ("previous year", FKDateTimeExampleSupport.offset(from: now, years: -1, months: -1)),
      ]
      self.appendOutput("reference → \(now.format(.dateTime))")
      for (label, sample) in samples {
        let text = sample.relative(style: .chat, reference: reference)
        self.appendOutput("\(label): \(sample.format(.dateTime)) → \"\(text)\"")
      }
    }
    addActionButton("Default relative() uses .chat") { [weak self] in
      let stamp = FKDateTimeExampleSupport.offset(minutes: -5)
      self?.appendOutput("relative() default → \"\(stamp.relative())\"")
    }

    addClearButton()
    appendOutput("Chat relative demo ready.")
  }
}
