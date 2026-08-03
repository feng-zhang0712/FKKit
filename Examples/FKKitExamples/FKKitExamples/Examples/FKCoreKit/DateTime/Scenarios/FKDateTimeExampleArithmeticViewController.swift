import FKCoreKit
import UIKit

/// Calendar arithmetic and startOf / endOf boundaries for every ``FKDateTimeUnit``.
final class FKDateTimeExampleArithmeticViewController: FKDateTimeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Arithmetic"

    addSection(
      title: "adding / subtracting",
      note: "All FKDateTimeUnit cases + DateComponents overload"
    )
    addActionButton("adding each unit (+1)") { [weak self] in
      let base = FKDateTime.now()
      self?.appendOutput("base → \(base.format(.dateTime))")
      for unit in FKDateTimeUnit.allCases {
        let next = base.adding(1, unit)
        self?.appendOutput("+1 \(unit.rawValue) (component=\(unit.calendarComponent)) → \(FKDateTimeExampleSupport.describe(next))")
      }
    }
    addActionButton("subtracting each unit (−1)") { [weak self] in
      let base = FKDateTime.now()
      for unit in FKDateTimeUnit.allCases {
        let prev = base.subtracting(1, unit)
        self?.appendOutput("-1 \(unit.rawValue) → \(FKDateTimeExampleSupport.describe(prev))")
      }
    }
    addActionButton("adding(DateComponents)") { [weak self] in
      var components = DateComponents()
      components.day = 2
      components.hour = 3
      components.minute = 15
      let next = FKDateTime.now().adding(components)
      self?.appendOutput("+2d 3h 15m → \(FKDateTimeExampleSupport.describe(next))")
    }

    addSection(title: "Boundaries", note: "startOf / endOf for each unit; startOfDay / endOfDay")
    addActionButton("startOf / endOf all units") { [weak self] in
      let base = FKDateTime.now()
      for unit in FKDateTimeUnit.allCases {
        let start = base.startOf(unit)
        let end = base.endOf(unit)
        self?.appendOutput("startOf(.\(unit.rawValue)) → \(FKDateTimeExampleSupport.describe(start))")
        self?.appendOutput("endOf(.\(unit.rawValue)) → \(FKDateTimeExampleSupport.describe(end))")
      }
    }
    addActionButton("startOfDay / endOfDay") { [weak self] in
      let base = FKDateTime.now()
      self?.appendOutput("startOfDay → \(FKDateTimeExampleSupport.describe(base.startOfDay))")
      self?.appendOutput("endOfDay → \(FKDateTimeExampleSupport.describe(base.endOfDay))")
    }

    addSection(
      title: "Mutating fields",
      note: "replacing(...), setting(_:to:), setting(hour:minute:second:)"
    )
    addActionButton("replacing year/month/day") { [weak self] in
      let base = FKDateTime.now()
      let next = base.replacing(year: 2030, month: 12, day: 25)
      self?.appendOutput("base → \(base.format(.dateTime))")
      self?.appendOutput("→ Dec 25 2030 → \(FKDateTimeExampleSupport.describe(next))")
    }
    addActionButton("setting(.hour, to: 9) + setting(hour:minute:second:)") { [weak self] in
      let base = FKDateTime.now()
      let byUnit = base.setting(.hour, to: 9)
      let byClock = base.setting(hour: 18, minute: 30, second: 0)
      self?.appendOutput("setting(.hour, 9) → \(FKDateTimeExampleSupport.describe(byUnit))")
      self?.appendOutput("setting(18:30:00) → \(FKDateTimeExampleSupport.describe(byClock))")
    }

    addClearButton()
    appendOutput("Arithmetic demo ready.")
  }
}
