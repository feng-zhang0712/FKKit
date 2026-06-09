import FKUIKit
import UIKit

/// Mock async search with ``setLoading(_:animated:)`` and disabled-input presentation.
final class FKSearchExampleLoadingSearchViewController: UIViewController {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.inlineCard(), placeholder: "Search (mock API)")
  private let modeControl = UISegmentedControl(items: ["Spinner", "Disabled input"])
  private let logView = FKSearchExampleSupport.makeEventLogTextView()
  private var searchTask: Task<Void, Never>?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Loading search"
    view.backgroundColor = .systemGroupedBackground

    modeControl.selectedSegmentIndex = 0
    modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

    searchBar.callbacks.onSearchQueryChanged = { [weak self] query in
      self?.performMockSearch(query: query)
    }
    searchBar.callbacks.onCancel = { [weak self] in
      self?.searchTask?.cancel()
      self?.searchBar.setLoading(false, animated: true)
      FKSearchExampleSupport.appendLog(self?.logView ?? UITextView(), "cancel — task cancelled")
    }

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel("Debounced query triggers a 1.2s mock request. Cancel aborts in-flight work."),
      searchBar,
      modeControl,
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

    modeChanged()
  }

  @objc private func modeChanged() {
    searchBar.apply {
      $0.loading.presentation = modeControl.selectedSegmentIndex == 1 ? .disabledInput : .activityIndicator
    }
  }

  private func performMockSearch(query: String) {
    searchTask?.cancel()
    searchBar.setLoading(true, animated: true)
    FKSearchExampleSupport.appendLog(logView, "loading start — \"\(query)\"")

    searchTask = Task { @MainActor [weak self] in
      guard let self else { return }
      try? await Task.sleep(nanoseconds: 1_200_000_000)
      guard !Task.isCancelled else { return }
      self.searchBar.setLoading(false, animated: true)
      let count = FKSearchExampleSupport.filter(FKSearchExampleSupport.catalogItems, query: query).count
      FKSearchExampleSupport.appendLog(self.logView, "loading finished — \(count) matches")
    }
  }

  deinit {
    searchTask?.cancel()
  }
}
