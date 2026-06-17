import FKUIKit
import XCTest

final class FKAudioLyricsParserTests: XCTestCase {
  func testParseExtractsSortedTimedLines() {
    let content = """
    [00:12.50]First line
    [01:02.00]Second line
    [00:30.00]Middle line
    """

    let lines = FKAudioLyricsParser.parse(content: content)

    XCTAssertEqual(lines.count, 3)
    XCTAssertEqual(lines[0].text, "First line")
    XCTAssertEqual(lines[1].text, "Middle line")
    XCTAssertEqual(lines[2].text, "Second line")
    XCTAssertEqual(lines[0].time, 12.5, accuracy: 0.001)
  }

  func testParseSupportsCentisecondTimestamp() {
    let content = "[00:01.25]Beat"

    let lines = FKAudioLyricsParser.parse(content: content)

    XCTAssertEqual(lines.count, 1)
    XCTAssertEqual(lines[0].time, 1.25, accuracy: 0.001)
  }

  func testActiveLineIndexReturnsLatestLineAtOrBeforeTime() {
    let lines = FKAudioLyricsParser.parse(content: """
    [00:00.00]A
    [00:10.00]B
    [00:20.00]C
    """)

    XCTAssertEqual(FKAudioLyricsParser.activeLineIndex(at: 0, in: lines), 0)
    XCTAssertEqual(FKAudioLyricsParser.activeLineIndex(at: 15, in: lines), 1)
    XCTAssertEqual(FKAudioLyricsParser.activeLineIndex(at: 20, in: lines), 2)
    XCTAssertNil(FKAudioLyricsParser.activeLineIndex(at: -1, in: lines))
  }

  func testParseReturnsEmptyArrayForNonLyricContent() throws {
    let lines = try FKAudioLyricsParser.parse(data: Data("plain text without timestamps".utf8))
    XCTAssertTrue(lines.isEmpty)
  }
}
