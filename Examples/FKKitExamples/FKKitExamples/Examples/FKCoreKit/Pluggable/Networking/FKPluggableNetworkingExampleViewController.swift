import FKCoreKit
import UIKit

/// Demonstrates networking pluggable contracts in `FKCoreKit/Pluggable/Networking`.
final class FKPluggableNetworkingExampleViewController: FKPluggableExampleBaseViewController {

  private let apiClient = DemoAPIClient()
  private let credentials = DemoCredentialStore()
  private let tokenRefresher = DemoTokenRefresher()
  private let reachability = DemoNetworkReachability()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Networking"
    apiClient.onPerform = { [weak self] line in
      Task { @MainActor in self?.appendOutput(line) }
    }

    addActionButton("1) FKAPIClientProviding.perform") { [weak self] in
      Task { await self?.runAPIClient() }
    }
    addActionButton("2) FKRequestIntercepting (Bearer header)") { [weak self] in
      self?.runRequestInterceptor()
    }
    addActionButton("3) FKResponseIntercepting (pass-through)") { [weak self] in
      self?.runResponseInterceptor()
    }
    addActionButton("4) FKRequestSigning (timestamp header)") { [weak self] in
      self?.runRequestSigner()
    }
    addActionButton("5) FKCredentialProviding + FKTokenRefreshing") { [weak self] in
      Task { await self?.runTokenFlow() }
    }
    addActionButton("6) FKNetworkReachabilityProviding") { [weak self] in
      guard let self else { return }
      appendOutput("isReachable = \(reachability.isReachable)")
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  private func runAPIClient() async {
    let url = URL(string: "https://api.example.com/v1/demo")!
    let request = FKAPIRequest(url: url, method: .post, body: Data("{\"ping\":1}".utf8))
    do {
      let response = try await apiClient.perform(request)
      appendOutput("Response bytes: \(response.data.count)")
    } catch {
      appendOutput("API error: \(error.localizedDescription)")
    }
  }

  private func runRequestInterceptor() {
    credentials.accessToken = "demo-token-123"
    let interceptor = DemoAuthHeaderInterceptor(credentials: credentials)
    var request = URLRequest(url: URL(string: "https://api.example.com/profile")!)
    do {
      request = try interceptor.intercept(request)
      let auth = request.value(forHTTPHeaderField: "Authorization") ?? "(none)"
      appendOutput("Authorization header: \(auth)")
    } catch {
      appendOutput("Interceptor error: \(error)")
    }
  }

  private func runResponseInterceptor() {
    let interceptor = DemoJSONResponseInterceptor()
    let data = Data("{\"items\":[]}".utf8)
    let response = HTTPURLResponse(
      url: URL(string: "https://api.example.com")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    )!
    do {
      let out = try interceptor.intercept(data: data, response: response)
      appendOutput("Response interceptor output: \(out.count) bytes")
    } catch {
      appendOutput("Response interceptor error: \(error)")
    }
  }

  private func runRequestSigner() {
    let signer = DemoTimestampRequestSigner()
    var request = URLRequest(url: URL(string: "https://api.example.com/orders")!)
    do {
      request = try signer.sign(request)
      let ts = request.value(forHTTPHeaderField: "X-Demo-Timestamp") ?? "?"
      appendOutput("X-Demo-Timestamp = \(ts)")
    } catch {
      appendOutput("Signer error: \(error)")
    }
  }

  private func runTokenFlow() async {
    credentials.refreshToken = "refresh-abc"
    do {
      let access = try await tokenRefresher.refreshAccessToken(using: credentials.refreshToken)
      credentials.accessToken = access
      appendOutput("New access token: \(access)")
    } catch {
      appendOutput("Refresh failed: \(error.localizedDescription)")
    }
  }
}
