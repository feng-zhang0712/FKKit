import FKUIKit
import UIKit

/// Return key (`.search`) submit, optional empty submit, and resign-on-submit toggle.
final class FKSearchExampleSubmitOnReturnViewController: UIViewController {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.inlineCard(), placeholder: "Press Search")
  private let logView = FKSearchExampleSupport.makeEventLogTextView()
  private let allowEmptySwitch = UISwitch()
  private let resignSwitch = UISwitch()
  private let resultLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Submit on Return"
    view.backgroundColor = .systemGroupedBackground

    allowEmptySwitch.isOn = false
    resignSwitch.isOn = false
    allowEmptySwitch.addTarget(self, action: #selector(configChanged), for: .valueChanged)
    resignSwitch.addTarget(self, action: #selector(configChanged), for: .valueChanged)

    resultLabel.font = .preferredFont(forTextStyle: .title3)
    resultLabel.textColor = .label
    resultLabel.numberOfLines = 0
    resultLabel.text = "Submitted query will appear here."

    searchBar.callbacks.onSubmit = { [weak self] query in
      guard let self else { return }
      FKSearchExampleSupport.appendLog(self.logView, "submit → \"\(query)\"")
      self.resultLabel.text = "Last submit: \"\(query)\""
    }
    searchBar.callbacks.onSearchQueryChanged = { [weak self] query in
      FKSearchExampleSupport.appendLog(self?.logView ?? UITextView(), "flush searchQueryChanged → \"\(query)\"")
    }
    searchBar.callbacks.onTextChanged = { [weak self] rawText in
      FKSearchExampleSupport.appendLog(self?.logView ?? UITextView(), "textChanged (raw) → \"\(rawText)\"")
    }

    let toggles = UIStackView(arrangedSubviews: [
      labeledRow(title: "Allow empty submit", control: allowEmptySwitch),
      labeledRow(title: "Resign on submit", control: resignSwitch),
    ])
    toggles.axis = .vertical
    toggles.spacing = 8

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel(
        "Submit flushes debounce immediately. Query callbacks use normalized text (default trims trailing whitespace). textChanged logs raw field text."
      ),
      searchBar,
      toggles,
      resultLabel,
    ])

    card.translatesAutoresizingMaskIntoConstraints = false
    logView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      logView.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 12),
      logView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    configChanged()
  }

  @objc private func configChanged() {
    searchBar.apply {
      $0.submit.allowsEmptySubmit = allowEmptySwitch.isOn
      $0.submit.submitResignsFirstResponder = resignSwitch.isOn
    }
  }

  private func labeledRow(title: String, control: UIView) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    let row = UIStackView(arrangedSubviews: [label, control])
    row.axis = .horizontal
    row.alignment = .center
    row.distribution = .equalSpacing
    return row
  }
}
