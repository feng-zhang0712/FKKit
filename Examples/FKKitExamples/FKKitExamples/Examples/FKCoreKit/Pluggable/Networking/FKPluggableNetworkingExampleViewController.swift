import FKCoreKit
import UIKit

/// Demonstrates networking pluggable contracts in `FKCoreKit/Pluggable/Networking`.
final class FKPluggableNetworkingExampleViewController: FKPluggableExampleBaseViewController {

  private let mockAPIClient = FKMockAPIClient()
  private let credentials = DemoCredentialStore()
  private let tokenRefresher = DemoTokenRefresher()

  private let demoAPIURL = URL(string: "https://api.example.com/v1/demo")!

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Networking"
    mockAPIClient.setResponse(
      .success(FKAPIResponse(data: Data("{\"ok\":true}".utf8), httpResponse: nil)),
      forURL: demoAPIURL
    )

    addActionButton("1) FKMockAPIClient.perform") { [weak self] in
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
    addActionButton("6) FKNetworkReachabilityProviding (live)") { [weak self] in
      let reachability = FKNetworkReachability()
      self?.appendOutput("FKNetworkReachability.isReachable = \(reachability.isReachable)")
    }
    addActionButton("7) FKMockReachability offline") { [weak self] in
      let offline = FKMockReachability(isReachable: false)
      self?.appendOutput("FKMockReachability.isReachable = \(offline.isReachable)")
    }
    addActionButton("8) FKNetworkClientPluggableAdapter (stub URL)") { [weak self] in
      Task { await self?.runPluggableNetworkAdapter() }
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  private func runAPIClient() async {
    let request = FKAPIRequest(url: demoAPIURL, method: .post, body: Data("{\"ping\":1}".utf8))
    do {
      let response = try await mockAPIClient.perform(request)
      appendOutput("FKMockAPIClient response bytes: \(response.data.count)")
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

  private func runPluggableNetworkAdapter() async {
    let mock = FKMockNetworkSession()
    let url = URL(string: "https://api.example.com/v1/pluggable")!
    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    mock.stubbedResponses[url] = (Data("{\"ok\":true}".utf8), response)
    let client = FKNetworkClient(transport: mock)
    let adapter = FKNetworkClientPluggableAdapter(client: client)
    let request = FKAPIRequest(url: url, method: .get, body: nil)
    do {
      let apiResponse = try await adapter.perform(request)
      appendOutput("Adapter response bytes: \(apiResponse.data.count)")
    } catch {
      appendOutput("Adapter error: \(error.localizedDescription)")
    }
  }
}
