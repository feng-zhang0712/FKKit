@testable import FKUIKit
import XCTest

final class FKWebHostPolicyEvaluatorTests: XCTestCase {
  func testHostMatchesExactHostCaseInsensitively() {
    XCTAssertTrue(FKWebHostPolicyEvaluator.hostMatches("Example.COM", patterns: ["example.com"]))
  }

  func testHostMatchesSubdomainSuffix() {
    XCTAssertTrue(FKWebHostPolicyEvaluator.hostMatches("api.example.com", patterns: ["example.com"]))
  }

  func testHostDoesNotMatchUnrelatedDomain() {
    XCTAssertFalse(FKWebHostPolicyEvaluator.hostMatches("example.org", patterns: ["example.com"]))
  }

  func testAllowAllPolicyAlwaysAllowsHTTPNavigation() {
    let url = URL(string: "https://any-host.example/path")!
    let disposition = FKWebHostPolicyEvaluator.evaluateHTTP(url: url, policy: .allowAll)

    XCTAssertEqual(disposition, .allow)
  }

  func testDomainListDeniesMatchingHost() {
    let url = URL(string: "https://blocked.example/login")!
    let policy = FKWebHTTPPolicy.domainList(
      FKWebDomainListPolicy(deniedHosts: ["blocked.example"])
    )

    XCTAssertEqual(FKWebHostPolicyEvaluator.evaluateHTTP(url: url, policy: policy), .cancel)
  }

  func testDomainListOpensExternalHostsInSystemBrowser() {
    let url = URL(string: "https://docs.example.com/help")!
    let policy = FKWebHTTPPolicy.domainList(
      FKWebDomainListPolicy(externalHosts: ["docs.example.com"])
    )

    XCTAssertEqual(
      FKWebHostPolicyEvaluator.evaluateHTTP(url: url, policy: policy),
      .openExternally(url)
    )
  }

  func testDomainListAllowsOnlyListedHostsWhenAllowlistPresent() {
    let allowedURL = URL(string: "https://app.example.com/home")!
    let blockedURL = URL(string: "https://other.example.com/home")!
    let policy = FKWebHTTPPolicy.domainList(
      FKWebDomainListPolicy(allowedHosts: ["app.example.com"])
    )

    XCTAssertEqual(FKWebHostPolicyEvaluator.evaluateHTTP(url: allowedURL, policy: policy), .allow)
    XCTAssertEqual(FKWebHostPolicyEvaluator.evaluateHTTP(url: blockedURL, policy: policy), .cancel)
  }

  func testDomainListAllowsUnknownHostWhenAllowlistMissing() {
    let url = URL(string: "https://open.example/page")!
    let policy = FKWebHTTPPolicy.domainList(FKWebDomainListPolicy(allowedHosts: nil))

    XCTAssertEqual(FKWebHostPolicyEvaluator.evaluateHTTP(url: url, policy: policy), .allow)
  }

  func testEvaluateHTTPAllowsURLWithoutHost() {
    let url = URL(string: "file:///local/page.html")!

    XCTAssertEqual(
      FKWebHostPolicyEvaluator.evaluateHTTP(url: url, policy: .allowAll),
      .allow
    )
  }

  func testDeniedHostsTakePrecedenceOverExternalHosts() {
    let url = URL(string: "https://shared.example/path")!
    let policy = FKWebHTTPPolicy.domainList(
      FKWebDomainListPolicy(
        deniedHosts: ["shared.example"],
        externalHosts: ["shared.example"]
      )
    )

    XCTAssertEqual(FKWebHostPolicyEvaluator.evaluateHTTP(url: url, policy: policy), .cancel)
  }
}
