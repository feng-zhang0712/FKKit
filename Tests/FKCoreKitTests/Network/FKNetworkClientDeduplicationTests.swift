import FKCoreKit
import XCTest

/// GET request that opts into in-flight deduplication.
private struct DedupUserRequest: Requestable {
  typealias Response = StubUserDTO

  let path: String
  var method: HTTPMethod { .get }
  var behavior: NetworkRequestBehavior { .idempotentDeduplicated }
}

final class FKNetworkClientDeduplicationTests: FKNetworkTestCase {
  func testConcurrentDuplicateRequestsReturnBusinessError() {
    NetworkTestFixtures.stubJSON(
      session: mockSession,
      path: "/user",
      json: #"{"id":1,"name":"Ada"}"#
    )
    mockSession.delay = 0.15

    let firstCompleted = expectation(description: "first request completes")
    let secondCompleted = expectation(description: "second request completes")
    let firstUserBox = LockedBox<StubUserDTO>()
    let secondErrorBox = LockedBox<NetworkError>()

    client.send(DedupUserRequest(path: "/user")) { result in
      if case let .success(user) = result {
        firstUserBox.set(user)
      } else {
        XCTFail("First request should succeed")
      }
      firstCompleted.fulfill()
    }

    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.02) { [client] in
      client.send(DedupUserRequest(path: "/user")) { result in
        if case let .failure(error) = result {
          secondErrorBox.set(error)
        } else {
          XCTFail("Second request should fail as duplicate")
        }
        secondCompleted.fulfill()
      }
    }

    wait(for: [firstCompleted, secondCompleted], timeout: 2)

    XCTAssertEqual(firstUserBox.get(), StubUserDTO(id: 1, name: "Ada"))
    guard case let .businessError(code, _) = secondErrorBox.get() else {
      XCTFail("Expected businessError, got \(String(describing: secondErrorBox.get()))")
      return
    }
    XCTAssertEqual(code, -2)
  }

  func testDedupKeyReleasedAfterCompletionAllowsRetry() async throws {
    NetworkTestFixtures.stubJSON(
      session: mockSession,
      path: "/user",
      json: #"{"id":2,"name":"Bob"}"#
    )

    let first = try await client.send(DedupUserRequest(path: "/user"))
    let second = try await client.send(DedupUserRequest(path: "/user"))

    XCTAssertEqual(first, StubUserDTO(id: 2, name: "Bob"))
    XCTAssertEqual(second, StubUserDTO(id: 2, name: "Bob"))
  }
}

private final class LockedBox<T>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: T?

  func set(_ value: T) {
    lock.lock()
    self.value = value
    lock.unlock()
  }

  func get() -> T? {
    lock.lock()
    defer { lock.unlock() }
    return value
  }
}
