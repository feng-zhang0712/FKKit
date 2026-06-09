import FKUIKit
import UIKit

/// Shared helpers for FKSearchBar / FKSearchField examples.
enum FKSearchExampleSupport {

  static let catalogItems: [String] = [
    "AirPods Pro",
    "Apple Watch",
    "Banana stand",
    "Bluetooth speaker",
    "Camera lens",
    "Cherry keyboard",
    "Desk lamp",
    "Ergonomic chair",
    "Fitness tracker",
    "Gaming mouse",
    "HDMI cable",
    "Instant camera",
    "Journal notebook",
    "Kindle case",
    "LED monitor",
    "Mechanical keyboard",
    "Noise-canceling headphones",
    "Office plant",
    "Portable charger",
    "Quiet fan",
    "Running shoes",
    "Smart thermostat",
    "Travel backpack",
    "USB-C hub",
    "Wireless earbuds",
  ]

  static func filter(_ items: [String], query: String) -> [String] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return items }
    return items.filter { $0.localizedCaseInsensitiveContains(trimmed) }
  }

  static func makeCaptionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    return label
  }

  static func makeCardStack(arrangedSubviews: [UIView]) -> UIStackView {
    let inner = UIStackView(arrangedSubviews: arrangedSubviews)
    inner.translatesAutoresizingMaskIntoConstraints = false
    inner.axis = .vertical
    inner.spacing = 10
    inner.isLayoutMarginsRelativeArrangement = true
    inner.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    let card = UIStackView(arrangedSubviews: [inner])
    card.translatesAutoresizingMaskIntoConstraints = false
    card.axis = .vertical
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.cornerRadius = 12
    card.layer.cornerCurve = .continuous
    card.clipsToBounds = true
    return card
  }

  static func makeEventLogTextView() -> UITextView {
    let view = UITextView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isEditable = false
    view.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    view.backgroundColor = .secondarySystemGroupedBackground
    view.layer.cornerRadius = 8
    view.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    return view
  }

  static func appendLog(_ logView: UITextView, _ line: String) {
    let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    logView.text += "[\(stamp)] \(line)\n"
    let end = NSRange(location: max(0, (logView.text as NSString).length - 1), length: 1)
    logView.scrollRangeToVisible(end)
  }

  static func pin(
    _ child: UIView,
    below anchor: NSLayoutYAxisAnchor,
    in host: UIView,
    topConstant: CGFloat = 12,
    horizontalInset: CGFloat = 16
  ) {
    child.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(child)
    NSLayoutConstraint.activate([
      child.topAnchor.constraint(equalTo: anchor, constant: topConstant),
      child.leadingAnchor.constraint(equalTo: host.layoutMarginsGuide.leadingAnchor, constant: horizontalInset - host.layoutMargins.left),
      child.trailingAnchor.constraint(equalTo: host.layoutMarginsGuide.trailingAnchor, constant: host.layoutMargins.right - horizontalInset),
    ])
  }
}
