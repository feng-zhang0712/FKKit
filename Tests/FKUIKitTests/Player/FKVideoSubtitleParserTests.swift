import FKUIKit
import XCTest

final class FKVideoSubtitleParserTests: XCTestCase {
  private let sampleSRT = """
  1
  00:00:01,000 --> 00:00:03,000
  Hello

  2
  00:00:04,000 --> 00:00:06,000
  World
  """

  private let sampleVTT = """
  WEBVTT

  00:00:01.000 --> 00:00:03.000
  Hello

  00:00:04.000 --> 00:00:06.000 align:start
  World
  """

  func testParseSRTExtractsCuesWithTimestamps() throws {
    let cues = try FKVideoSubtitleParser.parse(data: Data(sampleSRT.utf8), format: .srt)

    XCTAssertEqual(cues.count, 2)
    XCTAssertEqual(cues[0].start, 1, accuracy: 0.001)
    XCTAssertEqual(cues[0].end, 3, accuracy: 0.001)
    XCTAssertEqual(cues[0].text, "Hello")
    XCTAssertEqual(cues[1].text, "World")
  }

  func testParseVTTExtractsCuesAndIgnoresHeader() throws {
    let cues = try FKVideoSubtitleParser.parse(data: Data(sampleVTT.utf8), format: .vtt)

    XCTAssertEqual(cues.count, 2)
    XCTAssertEqual(cues[0].text, "Hello")
    XCTAssertEqual(cues[1].start, 4, accuracy: 0.001)
  }

  func testParseASSReturnsEmptyArray() throws {
    let cues = try FKVideoSubtitleParser.parse(data: Data("[Script Info]".utf8), format: .ass)

    XCTAssertTrue(cues.isEmpty)
  }

  func testParseReturnsEmptyArrayWhenContentHasNoCueStructure() throws {
    let cues = try FKVideoSubtitleParser.parse(data: Data("plain text without cues".utf8), format: .srt)

    XCTAssertTrue(cues.isEmpty)
  }

  func testCueLookupReturnsMatchingLine() throws {
    let cues = try FKVideoSubtitleParser.parse(data: Data(sampleSRT.utf8), format: .srt)

    XCTAssertEqual(FKVideoSubtitleParser.cue(at: 2, in: cues), "Hello")
    XCTAssertEqual(FKVideoSubtitleParser.cue(at: 5, in: cues), "World")
    XCTAssertNil(FKVideoSubtitleParser.cue(at: 3.5, in: cues))
  }
}
