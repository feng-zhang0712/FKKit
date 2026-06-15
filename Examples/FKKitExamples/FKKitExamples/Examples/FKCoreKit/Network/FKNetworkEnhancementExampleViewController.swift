import UIKit
import FKCoreKit

/// Demonstrates Network enhancement APIs: multipart, HTTP retry, mock session, SSL pinning, and pluggable adapter.
final class FKNetworkEnhancementExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let logView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Network Enhancements"
    view.backgroundColor = .systemBackground
    buildLayout()
    buildButtons()
    appendLog("Enhancement demos ready. Mock/retry/pinning run locally; multipart uses httpbin.org when online.")
  }

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.spacing = 8
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.layer.cornerRadius = 8
    logView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.45),
      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
      logView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func buildButtons() {
    addHeading("Multipart (E3/E4)")
    addButton("Multipart single file upload") { [weak self] in self?.runMultipartSingleFile() }
    addButton("Multipart mixed text + file fields") { [weak self] in self?.runMultipartMixedFields() }

    addHeading("HTTP retry (E5/E6)")
    addButton("Retry GET on 503 (mock session)") { [weak self] in self?.runRetryGET503() }
    addButton("POST does not retry (mock session)") { [weak self] in self?.runRetryPOSTNoRetry() }

    addHeading("Mock session (E7)")
    addButton("FKMockNetworkSession canned JSON") { [weak self] in self?.runMockSessionStub() }

    addHeading("SSL pinning (E1/E2)")
    addButton("Pinning validator mismatch → sslPinningFailed") { [weak self] in self?.runPinningFailureValidator() }
    addButton("Pinning validator success with empty pins skipped") { [weak self] in self?.runPinningNotConfigured() }

    addHeading("Pluggable (E9)")
    addButton("FKNetworkClientPluggableAdapter perform()") { [weak self] in self?.runPluggableAdapter() }

    addHeading("Reachability bridge")
    addButton("FKNetworkReachability as FKNetworkReachabilityProviding") { [weak self] in self?.runReachabilityConformance() }

    addButton("Clear log") { [weak self] in self?.logView.text = "" }
  }

  private func addHeading(_ text: String) {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.text = text
    contentStack.addArrangedSubview(label)
  }

  private func addButton(_ title: String, action: @escaping () -> Void) {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.contentHorizontalAlignment = .leading
    button.titleLabel?.numberOfLines = 0
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    contentStack.addArrangedSubview(button)
  }

  private func runMultipartSingleFile() {
    appendLog("[Multipart] Building single-file form…")
    var form = FKMultipartFormData()
    form.append("FKNetwork multipart demo", name: "description")
    if let imageData = UIImage(systemName: "star.fill")?.pngData() {
      form.append(imageData, name: "file", fileName: "demo.png", mimeType: "image/png")
    }
    let encoded = form.encode()
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("fk-multipart-body.bin")
    do {
      try encoded.body.write(to: tempURL, options: .atomic)
    } catch {
      appendLog("Failed to write temp body: \(error.localizedDescription)")
      return
    }

    var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
    request.httpMethod = "POST"
    request.setValue(encoded.contentType, forHTTPHeaderField: "Content-Type")

    let client = FKNetworkClient()
    client.upload(request, fileURL: tempURL, progress: nil) { [weak self] result in
      switch result {
      case let .success(data):
        self?.appendLog("[Multipart] upload OK, response bytes=\(data.count)")
      case let .failure(error):
        self?.appendLog("[Multipart] upload failed: \(error.localizedDescription)")
      }
    }
  }

  private func runMultipartMixedFields() {
    appendLog("[Multipart] Mixed fields + small text file")
    var form = FKMultipartFormData()
    form.append("alpha", name: "field_a")
    form.append("beta", name: "field_b")
    form.append(Data("hello multipart".utf8), name: "attachment", fileName: "note.txt")
    let encoded = form.encode()

    var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
    request.httpMethod = "POST"
    request.httpBody = encoded.body
    request.setValue(encoded.contentType, forHTTPHeaderField: "Content-Type")

    let client = FKNetworkClient()
    client.performAPIRequest(FKAPIRequest(url: request.url!, method: .post, headers: ["Content-Type": encoded.contentType], body: encoded.body)) { [weak self] result in
      switch result {
      case let .success(response):
        self?.appendLog("[Multipart] POST OK status=\(response.httpResponse?.statusCode ?? -1) bytes=\(response.data.count)")
      case let .failure(error):
        self?.appendLog("[Multipart] POST failed: \(error.localizedDescription)")
      }
    }
  }

  private func runRetryGET503() {
    appendLog("[Retry] conservativeGET against stubbed 503")
    let base = URL(string: "https://mock.fkkit.local")!
    let url = base.appendingPathComponent("retry-get")
    let response = HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: nil)!
    let mock = FKMockNetworkSession()
    mock.stubbedResponses[url] = (Data("{}".utf8), response)

    let config = FKNetworkConfiguration()
    config.environmentMap = [.development: FKEnvironmentConfig(baseURL: base)]
    config.environment = .development
    config.retryPolicy = .conservativeGET

    struct RetryGET: Requestable {
      typealias Response = FKNetworkEmptyKeyedResponse
      var path: String { "/retry-get" }
      var method: HTTPMethod { .get }
      var encoding: ParameterEncoding { .query }
    }

    let client = FKNetworkClient(config: config, transport: mock)
    client.send(RetryGET()) { [weak self] result in
      switch result {
      case .success:
        self?.appendLog("[Retry] unexpected success")
      case let .failure(error):
        self?.appendLog("[Retry] finished with \(self?.label(error) ?? "")")
      }
    }
  }

  private func runRetryPOSTNoRetry() {
    appendLog("[Retry] POST with conservativeGET should not retry")
    let base = URL(string: "https://mock.fkkit.local")!
    let url = base.appendingPathComponent("retry-post")
    let response = HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: nil)!
    let mock = FKMockNetworkSession()
    mock.stubbedResponses[url] = (Data("{}".utf8), response)

    let config = FKNetworkConfiguration()
    config.environmentMap = [.development: FKEnvironmentConfig(baseURL: base)]
    config.environment = .development
    config.retryPolicy = .conservativeGET

    struct RetryPOST: Requestable {
      typealias Response = FKNetworkEmptyKeyedResponse
      var path: String { "/retry-post" }
      var method: HTTPMethod { .post }
      var bodyParameters: [String: Any] { ["name": "retry-test"] }
    }

    let client = FKNetworkClient(config: config, transport: mock)
    client.send(RetryPOST()) { [weak self] result in
      switch result {
      case .success:
        self?.appendLog("[Retry] unexpected POST success")
      case let .failure(error):
        self?.appendLog("[Retry] POST finished with \(self?.label(error) ?? "") (no retry expected)")
      }
    }
  }

  private func runMockSessionStub() {
    appendLog("[MockSession] Stubbed JSON user")
    let base = URL(string: "https://mock.fkkit.local")!
    let url = base.appendingPathComponent("user")
    let payload = #"{"id":42,"name":"MockSessionUser"}"#.data(using: .utf8)!
    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
    let mock = FKMockNetworkSession()
    mock.stubbedResponses[url] = (payload, response)
    mock.delay = 0.2

    let config = FKNetworkConfiguration()
    config.environmentMap = [.development: FKEnvironmentConfig(baseURL: base)]
    config.environment = .development

    struct MockUserRequest: Requestable {
      typealias Response = FKNetworkDemoUser
      var path: String { "/user" }
      var method: HTTPMethod { .get }
    }

    let client = FKNetworkClient(config: config, transport: mock)
    client.send(MockUserRequest()) { [weak self] result in
      switch result {
      case let .success(user):
        self?.appendLog("[MockSession] decoded user id=\(user.id) name=\(user.name)")
      case let .failure(error):
        self?.appendLog("[MockSession] failed: \(error.localizedDescription)")
      }
    }
  }

  private func runPinningFailureValidator() {
    appendLog("[Pinning] Validator with mismatched pin hash")
    let config = FKSSLPinningConfiguration(
      pinnedHosts: ["example.com"],
      certificateHashes: ["example.com": [.init(base64Hash: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")]],
      publicKeyHashes: [:],
      enforceForSubdomains: false
    )
    appendLog("shouldPin(example.com)=\(FKSSLPinningValidator.shouldPin(host: "example.com", config: config))")
    appendLog("Live TLS validation requires a real challenge; configure sslPinning on FKNetworkConfiguration for transport-level enforcement.")
    appendLog("Expected failure type when mismatch: NetworkError.sslPinningFailed(host:)")
  }

  private func runPinningNotConfigured() {
    let config = FKSSLPinningConfiguration(pinnedHosts: ["example.com"], certificateHashes: [:], publicKeyHashes: [:])
    appendLog("[Pinning] Host pinned but no hashes → sslPinningNotConfigured at validate time")
    appendLog("pinnedHosts=\(config.pinnedHosts)")
  }

  private func runPluggableAdapter() {
    appendLog("[Pluggable] FKNetworkClientPluggableAdapter.perform")
    let url = URL(string: "https://mock.fkkit.local/pluggable")!
    let payload = #"{"ok":true}"#.data(using: .utf8)!
    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    let mock = FKMockNetworkSession()
    mock.stubbedResponses[url] = (payload, response)

    let config = FKNetworkConfiguration()
    let client = FKNetworkClient(config: config, transport: mock)
    let adapter = FKNetworkClientPluggableAdapter(client: client)

    Task {
      do {
        let apiResponse = try await adapter.perform(FKAPIRequest(url: url, method: .get))
        appendLog("[Pluggable] adapter OK bytes=\(apiResponse.data.count) status=\(apiResponse.httpResponse?.statusCode ?? -1)")
      } catch {
        appendLog("[Pluggable] adapter failed: \(error.localizedDescription)")
      }
    }
  }

  private func runReachabilityConformance() {
    if #available(iOS 12.0, *) {
      let reachability: any FKNetworkReachabilityProviding = FKNetworkReachability()
      appendLog("[Reachability] FKNetworkReachability conforms to FKNetworkReachabilityProviding, isReachable=\(reachability.isReachable)")
    } else {
      appendLog("Reachability requires iOS 12+")
    }
  }

  private func appendLog(_ message: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      logView.text.append(message + "\n")
      let end = NSRange(location: max(logView.text.count - 1, 0), length: 1)
      logView.scrollRangeToVisible(end)
    }
  }

  private func label(_ error: NetworkError) -> String {
    switch error {
    case let .retryExhausted(lastError):
      return "retryExhausted(\(lastError.localizedDescription))"
    case let .serverError(code, _):
      return "serverError(\(code))"
    default:
      return String(describing: error)
    }
  }
}
