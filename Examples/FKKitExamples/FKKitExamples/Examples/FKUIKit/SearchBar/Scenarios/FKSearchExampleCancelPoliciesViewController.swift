import FKUIKit
import UIKit

/// Compare ``FKSearchCancelPolicy`` behaviors side by side.
final class FKSearchExampleCancelPoliciesViewController: UIViewController {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.navigationBar(), placeholder: "Focus then cancel")
  private let policyControl = UISegmentedControl(items: ["Clear", "Resign only", "Revert"])
  private let logView = FKSearchExampleSupport.makeEventLogTextView()
  private let snapshotLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Cancel policies"
    view.backgroundColor = .systemGroupedBackground

    policyControl.selectedSegmentIndex = 0
    policyControl.addTarget(self, action: #selector(policyChanged), for: .valueChanged)

    snapshotLabel.font = .preferredFont(forTextStyle: .body)
    snapshotLabel.textColor = .secondaryLabel
    snapshotLabel.numberOfLines = 0
    snapshotLabel.text = "Edit text, then tap Cancel to observe policy."

    searchBar.callbacks.onEditingDidBegin = { [weak self] in
      FKSearchExampleSupport.appendLog(self?.logView ?? UITextView(), "snapshot at begin → \"\(self?.searchBar.text ?? "")\"")
    }
    searchBar.callbacks.onCancel = { [weak self] in
      guard let self else { return }
      FKSearchExampleSupport.appendLog(self.logView, "cancel — text now \"\(self.searchBar.text)\"")
    }

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel("`.navigationBar` preset with cancel visible while editing."),
      searchBar,
      policyControl,
      snapshotLabel,
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

    policyChanged()
  }

  @objc private func policyChanged() {
    let policy: FKSearchCancelPolicy = switch policyControl.selectedSegmentIndex {
    case 1: .resignOnly
    case 2: .revertAndResign
    default: .clearAndResign
    }
    searchBar.apply { $0.cancelButton.policy = policy }
    snapshotLabel.text = switch policy {
    case .clearAndResign: "Clear + resign: text emptied."
    case .resignOnly: "Resign only: text preserved."
    case .revertAndResign: "Revert + resign: restores text from editingDidBegin."
    }
  }
}
