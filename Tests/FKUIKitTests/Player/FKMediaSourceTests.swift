import FKUIKit
import XCTest

final class FKMediaSourceTests: XCTestCase {
  func testCandidateURLsReturnsPrimaryThenFallbacks() {
    let primary = URL(string: "https://cdn.example.com/primary.mp4")!
    let fallbackA = URL(string: "https://cdn.example.com/fallback-a.mp4")!
    let fallbackB = URL(string: "https://cdn.example.com/fallback-b.mp4")!
    let source = FKMediaSource.url(primary, fallbackURLs: [fallbackA, fallbackB])

    XCTAssertEqual(source.primaryURL, primary)
    XCTAssertEqual(source.candidateURLs, [primary, fallbackA, fallbackB])
  }

  func testHTTPHeadersExposeCustomValuesForURLSource() {
    let url = URL(string: "https://cdn.example.com/secure.mp4")!
    let source = FKMediaSource.url(url, headers: ["Authorization": "Bearer token"])

    XCTAssertEqual(source.httpHeaders["Authorization"], "Bearer token")
  }

  func testNonURLSourcesReturnEmptyCandidatesAndHeaders() {
    let source = FKMediaSource.offline(downloadIdentifier: "offline-1")

    XCTAssertNil(source.primaryURL)
    XCTAssertTrue(source.candidateURLs.isEmpty)
    XCTAssertTrue(source.httpHeaders.isEmpty)
  }
}
