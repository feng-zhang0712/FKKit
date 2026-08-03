import FKCoreKit
import UIKit

/// Parse, validate, format presets/styles, ISO-8601, and Unix timestamps.
final class FKDateTimeExampleParseFormatViewController: FKDateTimeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Parse & Format"

    addSection(title: "Parse", note: "parse(_:format:), parse(_:format: preset), parse(_:formats:), iso8601, isValid")
    addActionButton("parse custom format") { [weak self] in
      let value = FKDateTime.parse("2026-08-03 18:45:00", format: "yyyy-MM-dd HH:mm:ss")
      self?.appendOutput("custom → \(FKDateTimeExampleSupport.describe(value))")
    }
    addActionButton("parse all FKDateTimeFormatPreset cases") { [weak self] in
      guard let self else { return }
      let samples: [(FKDateTimeFormatPreset, String)] = [
        (.date, "2026-08-03"),
        (.time, "18:45:30"),
        (.timeShort, "18:45"),
        (.dateTime, "2026-08-03 18:45:30"),
        (.dateTimeShort, "2026-08-03 18:45"),
        (.monthDay, "08-03"),
        (.yearMonth, "2026-08"),
        (.iso8601Local, "2026-08-03T18:45:30"),
        (.iso8601Offset, "2026-08-03T18:45:30+0800"),
      ]
      for (preset, sample) in samples {
        let parsed = FKDateTime.parse(sample, format: preset)
        self.appendOutput("\(preset.rawValue) ← \"\(sample)\" → \(FKDateTimeExampleSupport.describe(parsed))")
      }
    }
    addActionButton("parse(formats:) fallback list") { [weak self] in
      let value = FKDateTime.parse(
        "03/08/2026",
        formats: ["yyyy-MM-dd", "dd/MM/yyyy", "MM-dd-yyyy"]
      )
      self?.appendOutput("multi → \(FKDateTimeExampleSupport.describe(value))")
    }
    addActionButton("iso8601 variants") { [weak self] in
      let inputs = [
        "2026-08-03T10:15:30.123Z",
        "2026-08-03T10:15:30Z",
        "2026-08-03T10:15:30+08:00",
        "2026-08-03 10:15:30",
        "2026-08-03",
        "not-a-date",
      ]
      for input in inputs {
        let value = FKDateTime.iso8601(input)
        self?.appendOutput("iso8601(\"\(input)\") → \(FKDateTimeExampleSupport.describe(value))")
      }
    }
    addActionButton("isValid round-trip") { [weak self] in
      let format = "yyyy-MM-dd HH:mm:ss"
      let good = FKDateTime.isValid("2026-08-03 18:00:00", format: format)
      let bad = FKDateTime.isValid("2026-13-40 99:99:99", format: format)
      self?.appendOutput("isValid good=\(good) bad=\(bad)")
    }

    addSection(title: "Format", note: "format(String), format(preset), format(dateStyle:timeStyle:), format(template:), iso8601String, unix")
    addActionButton("format presets + custom") { [weak self] in
      let value = FKDateTime.now()
      for preset in FKDateTimeFormatPreset.allCases {
        self?.appendOutput("\(preset) → \(value.format(preset))")
      }
      self?.appendOutput("custom EEEE → \(value.format("EEEE, MMM d yyyy"))")
    }
    addActionButton("format(dateStyle:timeStyle:)") { [weak self] in
      let value = FKDateTime.now()
      self?.appendOutput("short/short → \(value.format(dateStyle: .short, timeStyle: .short))")
      self?.appendOutput("medium/none → \(value.format(dateStyle: .medium, timeStyle: .none))")
      self?.appendOutput("full/full → \(value.format(dateStyle: .full, timeStyle: .full))")
    }
    addActionButton("format(template:) localized") { [weak self] in
      let value = FKDateTime.now()
      let en = value.in(locale: Locale(identifier: "en_US")).format(template: "yMMMMdjm")
      let zh = value.in(locale: Locale(identifier: "zh-Hans")).format(template: "yMMMMdjm")
      let de = value.in(locale: Locale(identifier: "de_DE")).format(template: "yMMMMdjm")
      self?.appendOutput("template yMMMMdjm en_US → \(en)")
      self?.appendOutput("template yMMMMdjm zh-Hans → \(zh)")
      self?.appendOutput("template yMMMMdjm de_DE → \(de)")
    }
    addActionButton("iso8601String + unix") { [weak self] in
      let value = FKDateTime.now()
      self?.appendOutput("iso frac → \(value.iso8601String(fractionalSeconds: true))")
      self?.appendOutput("iso plain → \(value.iso8601String(fractionalSeconds: false))")
      self?.appendOutput("unixTimestamp → \(value.unixTimestamp)")
      self?.appendOutput("unixMilliseconds → \(value.unixMilliseconds)")
    }

    addClearButton()
    appendOutput("Parse & format demo ready.")
  }
}
