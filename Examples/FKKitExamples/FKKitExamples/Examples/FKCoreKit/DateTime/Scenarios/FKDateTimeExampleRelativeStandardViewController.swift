import FKCoreKit
import UIKit

/// Conversational ``.standard`` (past/future) plus ``.system`` and fromNow / from(_:) APIs.
final class FKDateTimeExampleRelativeStandardViewController: FKDateTimeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Relative · Standard"

    addSection(
      title: "FKDateTimeRelativeStyle.standard",
      note: "Past: just now / seconds / minutes / hours / yesterday / day-before-yesterday / days / absolute. Future: in N units / tomorrow."
    )
    addActionButton("Past buckets") { [weak self] in
      guard let self else { return }
      let reference = Date()
      let now = FKDateTime(reference)
      let samples: [(String, FKDateTime)] = [
        ("just now (−10s)", FKDateTime(reference.addingTimeInterval(-10))),
        ("seconds (−45s)", FKDateTime(reference.addingTimeInterval(-45))),
        ("minutes (−8m)", FKDateTimeExampleSupport.offset(from: now, minutes: -8)),
        ("hours (−5h)", FKDateTimeExampleSupport.offset(from: now, hours: -5)),
        ("yesterday", FKDateTimeExampleSupport.offset(from: now, days: -1, hours: -3)),
        ("day before yesterday", FKDateTimeExampleSupport.offset(from: now, days: -2)),
        ("4 days ago", FKDateTimeExampleSupport.offset(from: now, days: -4)),
        ("earlier this year", FKDateTimeExampleSupport.offset(from: now, months: -3)),
        ("previous year", FKDateTimeExampleSupport.offset(from: now, years: -1)),
      ]
      for (label, sample) in samples {
        self.appendOutput("\(label) → \"\(sample.relative(style: .standard, reference: reference))\"")
      }
    }
    addActionButton("Future buckets") { [weak self] in
      guard let self else { return }
      let reference = Date()
      let now = FKDateTime(reference)
      let samples: [(String, FKDateTime)] = [
        ("near future (+10s)", FKDateTime(reference.addingTimeInterval(10))),
        ("in seconds (+45s)", FKDateTime(reference.addingTimeInterval(45))),
        ("in minutes (+8m)", FKDateTimeExampleSupport.offset(from: now, minutes: 8)),
        ("in hours (+5h)", FKDateTimeExampleSupport.offset(from: now, hours: 5)),
        ("tomorrow", FKDateTimeExampleSupport.offset(from: now, days: 1, hours: 2)),
        ("in 3 days", FKDateTimeExampleSupport.offset(from: now, days: 3)),
        ("later this year", FKDateTimeExampleSupport.offset(from: now, months: 2)),
        ("next year", FKDateTimeExampleSupport.offset(from: now, years: 1)),
      ]
      for (label, sample) in samples {
        self.appendOutput("\(label) → \"\(sample.relative(style: .standard, reference: reference))\"")
      }
    }

    addSection(title: "fromNow / from(_:)", note: "Moment-style aliases over relative(style:reference:)")
    addActionButton("fromNow(style: .standard)") { [weak self] in
      let past = FKDateTimeExampleSupport.offset(minutes: -20)
      let future = FKDateTimeExampleSupport.offset(hours: 2)
      self?.appendOutput("past fromNow → \"\(past.fromNow())\"")
      self?.appendOutput("future fromNow → \"\(future.fromNow(style: .standard))\"")
    }
    addActionButton("from(_ other:)") { [weak self] in
      let earlier = FKDateTimeExampleSupport.offset(hours: -6)
      let later = FKDateTime.now()
      self?.appendOutput("later.from(earlier) → \"\(later.from(earlier, style: .standard))\"")
      self?.appendOutput("earlier.from(later) → \"\(earlier.from(later, style: .standard))\"")
    }

    addSection(title: "System RelativeDateTimeFormatter", note: ".system(.full) and .system(.abbreviated)")
    addActionButton("system(.full) and .system(.abbreviated)") { [weak self] in
      let stamp = FKDateTimeExampleSupport.offset(hours: -6)
      self?.appendOutput("system full → \"\(stamp.relative(style: .system(.full)))\"")
      self?.appendOutput("system abbreviated → \"\(stamp.relative(style: .system(.abbreviated)))\"")
      self?.appendOutput("system short → \"\(stamp.relative(style: .system(.short)))\"")
    }

    addClearButton()
    appendOutput("Standard / system relative demo ready.")
  }
}
