import FKCoreKit
import XCTest

final class FKHashServiceTests: XCTestCase {
  private var security: FKSecurity!

  override func setUp() {
    super.setUp()
    security = FKSecurity()
  }

  override func tearDown() {
    security = nil
    super.tearDown()
  }

  func testHashStringSHA256MatchesKnownVector() async throws {
    let digest = try await security.hash(.sha256, string: Fixtures.Security.samplePlaintext)
    XCTAssertEqual(digest, Fixtures.Security.sha256Hello)
  }

  func testHashDataSHA256MatchesHashString() async throws {
    let data = Data(Fixtures.Security.samplePlaintext.utf8)
    let fromData = try await security.hash(.sha256, data: data)
    let fromString = try await security.hash(.sha256, string: Fixtures.Security.samplePlaintext)
    XCTAssertEqual(fromData, fromString)
  }

  func testHashFileMatchesHashData() async throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("fkkit-hash-\(UUID().uuidString).txt")
    defer { try? FileManager.default.removeItem(at: url) }

    try Data(Fixtures.Security.samplePlaintext.utf8).write(to: url)

    let fromFile = try await security.hash.hashFile(at: url, algorithm: .sha256)
    let fromData = try await security.hash(.sha256, data: Data(Fixtures.Security.samplePlaintext.utf8))
    XCTAssertEqual(fromFile, fromData)
  }
}
