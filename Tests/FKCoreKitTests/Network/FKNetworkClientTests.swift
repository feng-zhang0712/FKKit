import FKCoreKit
import XCTest

final class FKNetworkClientTests: FKNetworkTestCase {
  func testSendDecodesStubbedJSONSuccess() async throws {
    NetworkTestFixtures.stubJSON(
      session: mockSession,
      path: "/user",
      json: #"{"id":42,"name":"Ada"}"#
    )

    let user = try await client.send(StubUserRequest(path: "/user"))
    XCTAssertEqual(user, StubUserDTO(id: 42, name: "Ada"))
  }

  func testSendReturnsServerErrorForNon2xx() async {
    NetworkTestFixtures.stubJSON(
      session: mockSession,
      path: "/missing",
      statusCode: 404,
      json: #"{"error":"not found"}"#
    )

    do {
      _ = try await client.send(StubUserRequest(path: "/missing"))
      XCTFail("Expected serverError")
    } catch let error as NetworkError {
      guard case let .serverError(statusCode, _) = error else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      XCTAssertEqual(statusCode, 404)
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }

  func testSendReturnsOfflineWhenUnreachable() async {
    let offlineConfig = NetworkTestFixtures.makeConfiguration(
      networkStatusProvider: StubNetworkStatus(isReachable: false)
    )
    let offlineClient = FKNetworkClient(config: offlineConfig, transport: mockSession)

    do {
      _ = try await offlineClient.send(StubUserRequest(path: "/user"))
      XCTFail("Expected offline")
    } catch let error as NetworkError {
      guard case .offline = error else {
        XCTFail("Unexpected error: \(error)")
        return
      }
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }

  func testEnableMockUsesRequestMockDataWithoutTransport() async throws {
    let mockConfig = NetworkTestFixtures.makeConfiguration(enableMock: true)
    let mockClient = FKNetworkClient(config: mockConfig, transport: mockSession)

    let request = StubUserRequest(
      path: "/mock-user",
      mockData: #"{"id":7,"name":"Mock"}"#.data(using: .utf8)
    )

    let user = try await mockClient.send(request)
    XCTAssertEqual(user, StubUserDTO(id: 7, name: "Mock"))
  }

  func testSendReturnsDecodingFailedForInvalidJSON() async {
    NetworkTestFixtures.stubJSON(
      session: mockSession,
      path: "/bad-json",
      json: #"{"id":"not-a-number","name":"Bad"}"#
    )

    do {
      _ = try await client.send(StubUserRequest(path: "/bad-json"))
      XCTFail("Expected decodingFailed")
    } catch let error as NetworkError {
      guard case .decodingFailed = error else {
        XCTFail("Unexpected error: \(error)")
        return
      }
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }

  func testSendFailsWhenStubMissing() async {
    do {
      _ = try await client.send(StubUserRequest(path: "/unstubbed"))
      XCTFail("Expected failure when stub is missing")
    } catch is NetworkError {
      // Missing `FKMockNetworkSession` stub must not succeed; exact case may be `.underlying` after transport mapping.
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }

  func testSendReturnsInvalidURLWhenEnvironmentMissing() async {
    let invalidConfig = NetworkTestFixtures.makeConfiguration()
    invalidConfig.environmentMap = [:]
    let invalidClient = FKNetworkClient(config: invalidConfig, transport: mockSession)

    do {
      _ = try await invalidClient.send(StubUserRequest(path: "/user"))
      XCTFail("Expected invalidURL")
    } catch let error as NetworkError {
      guard case .invalidURL = error else {
        XCTFail("Unexpected error: \(error)")
        return
      }
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
}
