import FKCoreKit
import XCTest

final class FKMockAPIClientTests: XCTestCase {
  func testPerformReturnsStubbedResponseForMatchingURL() async throws {
    let client = FKMockAPIClient()
    let url = URL(string: "https://example.com/users")!
    let payload = Data("{\"ok\":true}".utf8)
    client.setResponse(.success(FKAPIResponse(data: payload, httpResponse: nil)), forURL: url)

    let request = FKAPIRequest(url: url)
    let response = try await client.perform(request)

    XCTAssertEqual(response.data, payload)
  }

  func testPerformThrowsStubbedError() async {
    let client = FKMockAPIClient()
    let url = URL(string: "https://example.com/fail")!
    enum TestError: Error { case failed }
    client.setResponse(.failure(TestError.failed), forURL: url)

    do {
      _ = try await client.perform(FKAPIRequest(url: url))
      XCTFail("Expected perform to throw")
    } catch is TestError {
      // Expected.
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testPerformReturnsEmptyResponseWhenNoStubExists() async throws {
    let client = FKMockAPIClient()
    let response = try await client.perform(FKAPIRequest(url: URL(string: "https://example.com/missing")!))
    XCTAssertTrue(response.data.isEmpty)
    XCTAssertNil(response.httpResponse)
  }

  func testPerformUsesDefaultResponseWhenURLSpecificStubMissing() async throws {
    let client = FKMockAPIClient()
    let payload = Data("fallback".utf8)
    client.setDefaultResponse(.success(FKAPIResponse(data: payload, httpResponse: nil)))

    let response = try await client.perform(FKAPIRequest(url: URL(string: "https://example.com/other")!))
    XCTAssertEqual(response.data, payload)
  }
}
