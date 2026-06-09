import FKUIKit
import UIKit

/// ``FKSearchBarDelegate`` fallback when ``FKSearchBar/callbacks`` handlers are unset.
final class FKSearchExampleDelegateLogViewController: UIViewController, FKSearchBarDelegate {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.inlineCard(), placeholder: "Type to log events")
  private let logView = FKSearchExampleSupport.makeEventLogTextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Delegate log"
    view.backgroundColor = .systemGroupedBackground

    searchBar.delegate = self

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel("Callbacks take precedence. This screen uses delegate only (no callbacks set)."),
      searchBar,
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

    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearLog))
  }

  @objc private func clearLog() {
    logView.text = ""
  }

  private func log(_ line: String) {
    FKSearchExampleSupport.appendLog(logView, line)
  }

  func searchBar(_ searchBar: FKSearchBar, textDidChange text: String) {
    log("textDidChange \"\(text)\"")
  }

  func searchBar(_ searchBar: FKSearchBar, searchQueryDidChange query: String) {
    log("searchQueryDidChange \"\(query)\"")
  }

  func searchBarSearchButtonClicked(_ searchBar: FKSearchBar) {
    log("searchButtonClicked")
  }

  func searchBarCancelButtonClicked(_ searchBar: FKSearchBar) {
    log("cancelButtonClicked")
  }

  func searchBarClearButtonClicked(_ searchBar: FKSearchBar) {
    log("clearButtonClicked")
  }

  func searchBarTextDidBeginEditing(_ searchBar: FKSearchBar) {
    log("textDidBeginEditing")
  }

  func searchBarTextDidEndEditing(_ searchBar: FKSearchBar) {
    log("textDidEndEditing")
  }
}
