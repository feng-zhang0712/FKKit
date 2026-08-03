import FKCoreKit
import UIKit

/// Component accessors, calendar flags, comparisons, age, and min/max.
final class FKDateTimeExampleQueryCompareViewController: FKDateTimeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Query & Compare"

    addSection(title: "Components", note: "year…second, weekday, weekOfYear, quarter, dayOfYear, daysInMonth")
    addActionButton("Dump components for now()") { [weak self] in
      let value = FKDateTime.now()
      self?.appendOutput(
        """
        \(value.format(.dateTime))
        y=\(value.year) mo=\(value.month) d=\(value.day) \
        h=\(value.hour) m=\(value.minute) s=\(value.second)
        weekday=\(value.weekday) weekOfYear=\(value.weekOfYear) \
        quarter=\(value.quarter) dayOfYear=\(value.dayOfYear) daysInMonth=\(value.daysInMonth)
        """
      )
    }

    addSection(title: "Flags", note: "isToday / yesterday / tomorrow / weekend / leapYear")
    addActionButton("Flags for now, ±1 day, weekend probe") { [weak self] in
      let now = FKDateTime.now()
      let yesterday = now.subtracting(1, .day) ?? now
      let tomorrow = now.adding(1, .day) ?? now
      self?.appendOutput("now isToday=\(now.isToday) isWeekend=\(now.isWeekend) isLeapYear=\(now.isLeapYear)")
      self?.appendOutput("yesterday isYesterday=\(yesterday.isYesterday) isToday=\(yesterday.isToday)")
      self?.appendOutput("tomorrow isTomorrow=\(tomorrow.isTomorrow)")
    }

    addSection(
      title: "Compare",
      note: "isSame, compare, before/after, sameOr*, isPast/isFuture, isBetween"
    )
    addActionButton("isSame / before / after / between") { [weak self] in
      let a = FKDateTime.now()
      let b = a.adding(2, .hour) ?? a
      let c = a.adding(1, .day) ?? a
      self?.appendOutput("same day a/b → \(a.isSame(.day, as: b))")
      self?.appendOutput("same hour a/b → \(a.isSame(.hour, as: b))")
      self?.appendOutput("a.isBefore(b)=\(a.isBefore(b)) a.isAfter(b)=\(a.isAfter(b))")
      self?.appendOutput("b.isBetween(a,c inclusive)=\(b.isBetween(a, and: c, inclusive: true))")
      self?.appendOutput("a.isBetween(a,c exclusive)=\(a.isBetween(a, and: c, inclusive: false))")
    }
    addActionButton("compare / sameOr* / past / future") { [weak self] in
      let now = FKDateTime.now()
      let earlier = now.subtracting(1, .day) ?? now
      let later = now.adding(1, .day) ?? now
      self?.appendOutput("compare(earlier, .day) → \(now.compare(to: earlier, granularity: .day).rawValue)")
      self?.appendOutput("sameOrBefore(earlier)=\(now.isSameOrBefore(earlier)) sameOrAfter(earlier)=\(now.isSameOrAfter(earlier))")
      self?.appendOutput("sameOrBefore(later, .day)=\(now.isSameOrBefore(later, granularity: .day))")
      self?.appendOutput("earlier.isPast=\(earlier.isPast()) later.isFuture=\(later.isFuture())")
    }

    addSection(title: "Age & extrema", note: "age(at:), FKDateTime.min / max")
    addActionButton("age(at:) from birth date") { [weak self] in
      let birth = FKDateTime.from(year: 1990, month: 5, day: 20) ?? .now()
      let age = birth.age()
      let ageAt = birth.age(at: FKDateTime.from(year: 2020, month: 5, day: 19) ?? .now())
      self?.appendOutput("birth=\(birth.format(.date)) age(now)=\(age.map(String.init) ?? "nil")")
      self?.appendOutput("age(at: 2020-05-19)=\(ageAt.map(String.init) ?? "nil")")
    }
    addActionButton("min / max") { [weak self] in
      let earlier = FKDateTimeExampleSupport.offset(days: -3)
      let later = FKDateTimeExampleSupport.offset(days: 3)
      let lo = FKDateTime.min(earlier, later)
      let hi = FKDateTime.max(earlier, later)
      self?.appendOutput("min → \(FKDateTimeExampleSupport.describe(lo))")
      self?.appendOutput("max → \(FKDateTimeExampleSupport.describe(hi))")
      self?.appendOutput("Comparable earlier < later → \(earlier < later)")
      self?.appendOutput("Hashable set count → \(Set([earlier, earlier, later]).count)")
    }

    addClearButton()
    appendOutput("Query & compare demo ready.")
  }
}
