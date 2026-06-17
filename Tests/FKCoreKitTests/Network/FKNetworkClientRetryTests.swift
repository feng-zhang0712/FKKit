import FKCoreKit
import XCTest

final class FKNetworkClientRetryTests: XCTestCase {
  func testSendRetries503AndEventuallyDecodesSuccess() async throws {
    let successJSON = #"{"id":99,"name":"Retry"}"#
    let transport = SequentialStatusNetworkSession(
      statusCodes: [503, 200],
      successBody: Data(successJSON.utf8)
    )
    let retryConfig = NetworkTestFixtures.makeConfiguration(
      callbackOnMainQueue: false,
      retryPolicy: FKNetworkRetryPolicy(
        maxRetryCount: 2,
        backoff: .constant(0),
        retryableHTTPStatusCodes: [503],
        idempotentMethodsOnly: true
      )
    )
    let retryClient = FKNetworkClient(config: retryConfig, transport: transport)

    let user = try await retryClient.send(StubUserRequest(path: "/retry-user"))
    XCTAssertEqual(user, StubUserDTO(id: 99, name: "Retry"))
  }

  func testSendReturnsRetryExhaustedAfterRepeated503() async {
    let transport = SequentialStatusNetworkSession(
      statusCodes: [503, 503, 503],
      successBody: Data()
    )
    let retryConfig = NetworkTestFixtures.makeConfiguration(
      callbackOnMainQueue: false,
      retryPolicy: FKNetworkRetryPolicy(
        maxRetryCount: 2,
        backoff: .constant(0),
        retryableHTTPStatusCodes: [503],
        idempotentMethodsOnly: true
      )
    )
    let retryClient = FKNetworkClient(config: retryConfig, transport: transport)

    do {
      _ = try await retryClient.send(StubUserRequest(path: "/retry-exhausted"))
      XCTFail("Expected retryExhausted")
    } catch let error as NetworkError {
      guard case .retryExhausted = error else {
        XCTFail("Unexpected error: \(error)")
        return
      }
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }

  func testPOSTIsNotRetriedWhenIdempotentMethodsOnly() async {
    let transport = SequentialStatusNetworkSession(
      statusCodes: [503, 200],
      successBody: Data(#"{"id":1,"name":"X"}"#.utf8)
    )
    let retryConfig = NetworkTestFixtures.makeConfiguration(
      callbackOnMainQueue: false,
      retryPolicy: FKNetworkRetryPolicy(
        maxRetryCount: 2,
        backoff: .constant(0),
        retryableHTTPStatusCodes: [503],
        idempotentMethodsOnly: true
      )
    )
    let retryClient = FKNetworkClient(config: retryConfig, transport: transport)

    do {
      _ = try await retryClient.send(StubPostRequest(path: "/retry-post"))
      XCTFail("Expected serverError without retry")
    } catch let error as NetworkError {
      guard case let .serverError(statusCode, _) = error else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      XCTAssertEqual(statusCode, 503)
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
}

private struct StubPostRequest: Requestable {
  typealias Response = StubUserDTO

  let path: String
  var method: HTTPMethod { .post }
}
