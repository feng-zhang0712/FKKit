import UIKit

/// Full ``FKWebView`` capability coverage grouped by integration topic.
final class FKWebViewExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "Getting started",
      rows: [
        Row(
          title: "Remote HTTPS load",
          subtitle: "Default configuration · linear progress · example.com",
          make: { FKWebViewExampleBasicLoadViewController() }
        ),
        Row(
          title: "Local HTML & file URL",
          subtitle: "loadHTMLString · loadFileURL · bundled demo page",
          make: { FKWebViewExampleLocalHTMLViewController() }
        ),
        Row(
          title: "FKWebViewController host",
          subtitle: "FKWebViewDefaults.inAppBrowser() · navigation title · close bar button",
          make: { FKWebViewExampleHostViewController() }
        ),
      ]
    ),
    Section(
      title: "Chrome & progress",
      rows: [
        Row(
          title: "Toolbar & history",
          subtitle: "Bundled 3-page file navigation · back · forward · reload/stop · close",
          make: { FKWebViewExampleToolbarViewController() }
        ),
        Row(
          title: "Progress presentation",
          subtitle: "linearBar · top safe area · indeterminate · none",
          make: { FKWebViewExampleProgressModesViewController() }
        ),
        Row(
          title: "Pull to refresh",
          subtitle: "UIRefreshControl on the internal scroll view",
          make: { FKWebViewExamplePullToRefreshViewController() }
        ),
      ]
    ),
    Section(
      title: "Errors & offline",
      rows: [
        Row(
          title: "HTTP error · retry · Safari",
          subtitle: "FKEmptyState overlay · httpbingo.org/status/404",
          make: { FKWebViewExampleErrorRetryViewController() }
        ),
        Row(
          title: "Offline preflight",
          subtitle: "NetworkStatusProviding stub · skip load when offline",
          make: { FKWebViewExampleOfflinePreflightViewController() }
        ),
      ]
    ),
    Section(
      title: "Navigation policy",
      rows: [
        Row(
          title: "External links (target=_blank)",
          subtitle: "FKWebTargetBlankPolicy.openExternally → Safari",
          make: { FKWebViewExampleExternalLinksViewController() }
        ),
        Row(
          title: "Domain allowlist",
          subtitle: "allowedHosts · hostDenied empty state",
          make: { FKWebViewExampleDomainPolicyViewController() }
        ),
        Row(
          title: "mailto & tel",
          subtitle: "FKWebSystemURLPolicy.openExternally",
          make: { FKWebViewExampleSystemLinksViewController() }
        ),
      ]
    ),
    Section(
      title: "JavaScript & auth",
      rows: [
        Row(
          title: "JavaScript bridge",
          subtitle: "Multi-handler · nested JSON · request/response · native push",
          make: { FKWebViewExampleJavaScriptBridgeViewController() }
        ),
        Row(
          title: "JavaScript dialogs",
          subtitle: "WKUIDelegate alert · confirm · prompt defaults",
          make: { FKWebViewExampleJavaScriptDialogsViewController() }
        ),
        Row(
          title: "OAuth redirect intercept",
          subtitle: "Custom scheme · onOAuthRedirect · ephemeralAuth preset",
          make: { FKWebViewExampleOAuthRedirectViewController() }
        ),
      ]
    ),
    Section(
      title: "Integration",
      rows: [
        Row(
          title: "Delegate & callbacks log",
          subtitle: "Lifecycle · state · commit/finish/fail · request headers",
          make: { FKWebViewExampleDelegateLogViewController() }
        ),
        Row(
          title: "SwiftUI representable",
          subtitle: "FKWebViewRepresentable · picker-driven URL reload",
          make: { FKWebViewExampleSwiftUIViewController() }
        ),
        Row(
          title: "Sheet presentation",
          subtitle: "FKSheetPresentationController · centered in-app browser",
          make: { FKWebViewExampleSheetEmbedViewController() }
        ),
        Row(
          title: "Ephemeral data store",
          subtitle: "nonPersistent session · clearWebsiteData API",
          make: { FKWebViewExampleEphemeralAuthViewController() }
        ),
      ]
    ),
  ]

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKWebView"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 72
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var content = cell.defaultContentConfiguration()
    content.text = row.title
    content.secondaryText = row.subtitle
    content.secondaryTextProperties.numberOfLines = 0
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
