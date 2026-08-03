import FKCoreKit
import UIKit

/// ``FKDateTimeConfiguration`` presets and context switching.
final class FKDateTimeExampleConfigurationViewController: FKDateTimeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Configuration"

    addSection(title: "Presets", note: ".default vs .utc (Gregorian + en_US_POSIX)")
    addActionButton("Compare .default and .utc formatting") { [weak self] in
      let instant = Date()
      let local = FKDateTime(instant, configuration: .default)
      let utc = FKDateTime(instant, configuration: .utc)
      self?.appendOutput("default → \(local.format(.dateTime)) locale=\(local.configuration.locale.identifier)")
      self?.appendOutput("utc → \(utc.format(.dateTime)) locale=\(utc.configuration.locale.identifier)")
    }

    addSection(
      title: "Configuration.with",
      note: "with(timeZone:), with(locale:), with(calendar:)"
    )
    addActionButton("with(timeZone: Asia/Shanghai)") { [weak self] in
      guard let shanghai = TimeZone(identifier: "Asia/Shanghai") else { return }
      let config = FKDateTimeConfiguration.utc.with(timeZone: shanghai)
      let value = FKDateTime.now(configuration: config)
      self?.appendOutput("Shanghai → \(value.format(.dateTime)) tz=\(config.timeZone.identifier)")
    }
    addActionButton("with(locale: zh-Hans) weekday") { [weak self] in
      let config = FKDateTimeConfiguration.default.with(locale: Locale(identifier: "zh-Hans"))
      let value = FKDateTime.now(configuration: config)
      self?.appendOutput("zh-Hans EEEE → \(value.format("EEEE"))")
    }
    addActionButton("with(calendar: gregorian) vs iso8601") { [weak self] in
      var iso = Calendar(identifier: .iso8601)
      iso.firstWeekday = 2
      let config = FKDateTimeConfiguration.default.with(calendar: iso)
      let value = FKDateTime.now(configuration: config)
      self?.appendOutput("iso8601 calendar weekday=\(value.weekday) weekOfYear=\(value.weekOfYear)")
    }

    addSection(title: "Instance context", note: "with(configuration:), in(timeZone:), in(locale:)")
    addActionButton("now().in(timeZone: UTC)") { [weak self] in
      let value = FKDateTime.now().in(timeZone: .fk_utc)
      self?.appendOutput("in UTC → \(FKDateTimeExampleSupport.describe(value))")
    }
    addActionButton("now().in(locale: ja_JP)") { [weak self] in
      let value = FKDateTime.now().in(locale: Locale(identifier: "ja_JP"))
      self?.appendOutput("ja_JP medium style → \(value.format(dateStyle: .medium, timeStyle: .short))")
    }
    addActionButton("with(configuration: .utc)") { [weak self] in
      let value = FKDateTime.now().with(configuration: .utc)
      self?.appendOutput("with utc → \(FKDateTimeExampleSupport.describe(value))")
    }

    addClearButton()
    appendOutput("Configuration demo ready.")
  }
}
