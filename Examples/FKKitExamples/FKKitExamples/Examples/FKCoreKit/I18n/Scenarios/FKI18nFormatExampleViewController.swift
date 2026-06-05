import FKCoreKit
import UIKit

/// Demonstrates interpolation, format strings, formatters, and plural counts.
final class FKI18nFormatExampleViewController: FKI18nExampleBaseViewController {

  private let previewLabel = UILabel()
  private var itemCount = 3

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Format & Variables"

    previewLabel.font = .preferredFont(forTextStyle: .body)
    previewLabel.numberOfLines = 0
    stackView.insertArrangedSubview(previewLabel, at: 0)

    addInfoLabel("Covers localized(_:variables:), localizedFormat, localizedPlural, and FKI18nFormatterProvider.")
    addLanguagePickerButton()
    addActionButton("Run Format Demo") { [weak self] in
      self?.runFormatDemo()
    }
    addActionButton("Increment Item Count") { [weak self] in
      guard let self else { return }
      self.itemCount = (self.itemCount + 1) % 6
      self.runFormatDemo()
    }
    addActionButton("Clear Log") { [weak self] in
      self?.clearOutput()
    }

    refreshLocalizedContent()
    runFormatDemo()
  }

  override func refreshLocalizedContent() {
    runFormatDemo()
  }

  private func runFormatDemo() {
    let i18n = FKI18nManager.shared
    clearOutput()

    let named = i18n.localized(
      "i18n.demo.greeting.named",
      table: FKI18nExampleSupport.demoTable,
      variables: ["name": "FKKit"]
    )
    appendOutput("variables: \(named)")

    let priceText = i18n.formatters.numberFormatter(style: .currency)
      .string(from: NSNumber(value: 1299.99)) ?? "1299.99"
    let price = i18n.localizedFormat(
      "i18n.demo.format.price",
      table: FKI18nExampleSupport.demoTable,
      arguments: [priceText]
    )
    appendOutput("format: \(price)")

    let today = i18n.formatters.dateFormatter(dateStyle: .full, timeStyle: .none)
      .string(from: Date())
    let dateLine = i18n.localizedFormat(
      "i18n.demo.format.date.label",
      table: FKI18nExampleSupport.demoTable,
      arguments: [today]
    )
    appendOutput("date: \(dateLine)")

    let plural = i18n.localizedPlural(
      "i18n.demo.items.count",
      count: itemCount,
      table: FKI18nExampleSupport.demoTable
    )
    appendOutput("plural(\(itemCount)): \(plural)")

    let number = i18n.formatters.numberFormatter(style: .decimal).string(from: NSNumber(value: 1_234_567)) ?? "-"
    appendOutput("formatter: \(number)")

    previewLabel.text = [named, plural].joined(separator: "\n")
  }
}
