import FKCoreKit
import UIKit

/// Per-unit and multi-unit diffs plus ``FKDateTimeDiff`` fields.
final class FKDateTimeExampleDiffViewController: FKDateTimeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Diff"

    addSection(title: "Per-unit diff", note: "diff(_:unit:) for every FKDateTimeUnit")
    addActionButton("diff each unit to +10 days 5 hours") { [weak self] in
      let start = FKDateTime.now()
      let end = FKDateTimeExampleSupport.offset(from: start, days: 10, hours: 5)
      self?.appendOutput("start → \(start.format(.dateTime))")
      self?.appendOutput("end → \(end.format(.dateTime))")
      for unit in FKDateTimeUnit.allCases {
        let delta = start.diff(end, unit: unit)
        self?.appendOutput("diff(.\(unit.rawValue)) → \(delta.map(String.init) ?? "nil")")
      }
    }

    addSection(title: "Multi-unit diff", note: "diff(to:) → FKDateTimeDiff")
    addActionButton("diff(to:) forward") { [weak self] in
      let start = FKDateTime.from(year: 2024, month: 1, day: 1, hour: 8) ?? .now()
      let end = FKDateTime.from(year: 2026, month: 8, day: 3, hour: 18, minute: 30) ?? .now()
      let diff = start.diff(to: end)
      self?.appendOutput("forward → \(FKDateTimeExampleSupport.describe(diff))")
    }
    addActionButton("diff(to:) backward (negative)") { [weak self] in
      let start = FKDateTime.now()
      let past = FKDateTimeExampleSupport.offset(from: start, days: -2, hours: -4)
      let diff = start.diff(to: past)
      self?.appendOutput("backward → \(FKDateTimeExampleSupport.describe(diff))")
    }

    addSection(title: "Day distance", note: "daysUntil(_:) between midnights")
    addActionButton("daysUntil samples") { [weak self] in
      let today = FKDateTime.now()
      let tomorrow = today.adding(1, .day) ?? today
      let nextWeek = today.adding(7, .day) ?? today
      let yesterday = today.subtracting(1, .day) ?? today
      self?.appendOutput("daysUntil(tomorrow)=\(today.daysUntil(tomorrow).map(String.init) ?? "nil")")
      self?.appendOutput("daysUntil(+7d)=\(today.daysUntil(nextWeek).map(String.init) ?? "nil")")
      self?.appendOutput("daysUntil(yesterday)=\(today.daysUntil(yesterday).map(String.init) ?? "nil")")
    }

    addSection(
      title: "Duration description",
      note: "durationDescription(to:) — span length (not social relative text)"
    )
    addActionButton("durationDescription styles") { [weak self] in
      let start = FKDateTime.now()
      let end = FKDateTimeExampleSupport.offset(from: start, days: 1, hours: 2, minutes: 15, seconds: 40)
      let abbreviated = start.durationDescription(to: end)
      let full = start.durationDescription(to: end, unitsStyle: .full, maximumUnitCount: 3)
      let positional = start.durationDescription(
        to: end,
        allowedUnits: [.hour, .minute, .second],
        unitsStyle: .positional,
        maximumUnitCount: 0
      )
      self?.appendOutput("abbr → \(abbreviated ?? "nil")")
      self?.appendOutput("full → \(full ?? "nil")")
      self?.appendOutput("positional hms → \(positional ?? "nil")")
    }

    addClearButton()
    appendOutput("Diff demo ready.")
  }
}
