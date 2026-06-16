import FKCoreKit
import Foundation
import XCTest

final class FKBuildTimeAppEnvironmentTests: XCTestCase {
  func testExplicitInitializerStoresEnvironmentAndURLs() {
    let apiURL = URL(string: "https://api.test.local")!
    let webURL = URL(string: "https://web.test.local")!
    let environment = FKBuildTimeAppEnvironment(
      environment: .staging,
      apiBaseURL: apiURL,
      webBaseURL: webURL
    )

    XCTAssertEqual(environment.environment, .staging)
    XCTAssertEqual(environment.apiBaseURL, apiURL)
    XCTAssertEqual(environment.webBaseURL, webURL)
  }

  func testPlistInitializerReadsConfiguredEnvironmentAndURLs() {
    let plist: [String: Any] = [
      "FKAppEnvironment": "staging",
      "FKAPIBaseURL": "https://api.staging.example",
      "FKWebBaseURL": "https://web.staging.example"
    ]
    let environment = FKBuildTimeAppEnvironment(plist: plist)

    XCTAssertEqual(environment.environment, .staging)
    XCTAssertEqual(environment.apiBaseURL.absoluteString, "https://api.staging.example")
    XCTAssertEqual(environment.webBaseURL?.absoluteString, "https://web.staging.example")
  }

  func testPlistInitializerFallsBackToDefaultAPIBaseURLWhenMissing() {
    let environment = FKBuildTimeAppEnvironment(plist: [:])

    XCTAssertEqual(environment.apiBaseURL.absoluteString, "https://api.example.com")
    XCTAssertNil(environment.webBaseURL)
  }
}
