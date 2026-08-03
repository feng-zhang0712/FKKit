import FKCoreKit
import UIKit

/// Construction factories, Date bridge, description, and Codable round-trip.
final class FKDateTimeExampleBasicsViewController: FKDateTimeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basics & Codable"

    addSection(
      title: "Factories",
      note: "FKDateTime.now, from(unixTimestamp:), from(unixMilliseconds:), from(year:month:day:…)"
    )
    addActionButton("now()") { [weak self] in
      let value = FKDateTime.now()
      self?.appendOutput("now → \(FKDateTimeExampleSupport.describe(value))")
      self?.appendOutput("description → \(value.description)")
    }
    addActionButton("from(unixTimestamp:)") { [weak self] in
      let stamp: TimeInterval = 1_704_067_200 // 2024-01-01 00:00:00 UTC
      let value = FKDateTime.from(unixTimestamp: stamp, configuration: .utc)
      self?.appendOutput("unix \(stamp) → \(FKDateTimeExampleSupport.describe(value))")
    }
    addActionButton("from(unixMilliseconds:)") { [weak self] in
      let ms: Int64 = 1_704_067_200_000
      let value = FKDateTime.from(unixMilliseconds: ms, configuration: .utc)
      self?.appendOutput("ms \(ms) → \(FKDateTimeExampleSupport.describe(value))")
    }
    addActionButton("from(year:month:day:hour:minute:second:)") { [weak self] in
      let value = FKDateTime.from(year: 2026, month: 8, day: 3, hour: 18, minute: 30, second: 15)
      self?.appendOutput("components → \(FKDateTimeExampleSupport.describe(value))")
      let invalid = FKDateTime.from(year: 2026, month: 13, day: 40)
      self?.appendOutput("invalid components → \(FKDateTimeExampleSupport.describe(invalid))")
    }

    addSection(title: "Date bridge", note: "Date.fk_dateTime and fk_dateTime(configuration:)")
    addActionButton("Date().fk_dateTime") { [weak self] in
      let value = Date().fk_dateTime
      self?.appendOutput("fk_dateTime → \(FKDateTimeExampleSupport.describe(value))")
    }
    addActionButton("fk_dateTime(configuration: .utc)") { [weak self] in
      let value = Date().fk_dateTime(configuration: .utc)
      self?.appendOutput("utc bridge → \(FKDateTimeExampleSupport.describe(value))")
    }

    addSection(title: "Codable", note: "Single-value TimeInterval encode; decode TimeInterval / ISO string / Date")
    addActionButton("JSON encode → decode (TimeInterval)") { [weak self] in
      let original = FKDateTime.now()
      do {
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FKDateTime.self, from: data)
        self?.appendOutput("encoded JSON: \(String(data: data, encoding: .utf8) ?? "?")")
        self?.appendOutput("decoded → \(FKDateTimeExampleSupport.describe(decoded))")
        self?.appendOutput("equal instants: \(original == decoded)")
      } catch {
        self?.appendOutput("Codable error: \(error)")
      }
    }
    addActionButton("Decode ISO-8601 JSON string") { [weak self] in
      let json = Data(#""2026-08-03T10:15:30Z""#.utf8)
      do {
        let decoded = try JSONDecoder().decode(FKDateTime.self, from: json)
        self?.appendOutput("ISO string decode → \(FKDateTimeExampleSupport.describe(decoded))")
      } catch {
        self?.appendOutput("Decode error: \(error)")
      }
    }

    addClearButton()
    appendOutput("Basics demo ready.")
  }
}
