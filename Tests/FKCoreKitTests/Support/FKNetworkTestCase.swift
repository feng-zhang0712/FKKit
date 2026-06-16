import FKCoreKit
import XCTest

/// Base test case that provisions an isolated ``FKNetworkClient`` backed by ``FKMockNetworkSession``.
class FKNetworkTestCase: XCTestCase {
  private(set) var mockSession: FKMockNetworkSession!
  private(set) var config: FKNetworkConfiguration!
  private(set) var client: FKNetworkClient!

  override func setUp() {
    super.setUp()
    mockSession = FKMockNetworkSession()
    config = NetworkTestFixtures.makeConfiguration()
    client = FKNetworkClient(config: config, transport: mockSession)
  }

  override func tearDown() {
    client = nil
    config = nil
    mockSession = nil
    super.tearDown()
  }
}
