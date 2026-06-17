import FKCoreKit
import UIKit
import Foundation

/// FKNetworkClient with custom decoder and envelope interceptor.
final class FKModelMappingExampleNetworkIntegrationViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Network Integration"
    addInfoLabel("FKNetworkClient + FKJSONCodec + FKResponseEnvelopeInterceptor + mock data.")
    addActionButton("Mock request with envelope interceptor") { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        self.appendOutput("--- Network mock ---")
        do {
          let codec = FKJSONCodec(configuration: .standard)
          let env = FKEnvironmentConfig(baseURL: URL(string: "https://example.com")!)
          let config = FKNetworkConfiguration(
            environment: .development,
            environmentMap: [.development: env],
            responseInterceptors: [FKResponseEnvelopeInterceptor(configuration: .standard)]
          )
          config.enableMock = true
          let client = FKNetworkClient(config: config, decoder: codec.makeDecoder())
          let user = try await client.send(FKModelMappingDemoEnvelopeUserRequest())
          self.appendOutput("Network decoded: \(user.displayName) <\(user.email)>")
        } catch {
          self.appendOutput(FKModelMappingExampleSupport.describe(error: error))
        }
      }
    }
    addActionButton("Interceptor only (no client)") { [weak self] in
      self?.runMapping("Interceptor") {
        let interceptor = FKResponseEnvelopeInterceptor(configuration: .standard)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let payload = try interceptor.intercept(data: FKModelMappingExampleSupport.Payload.envelopeSuccess, response: response)
        let user = try FKJSONCodec(configuration: .standard).decode(FKModelMappingDemoUser.self, from: payload)
        return "Intercepted payload user=\(user.displayName)"
      }
    }
  }
}
