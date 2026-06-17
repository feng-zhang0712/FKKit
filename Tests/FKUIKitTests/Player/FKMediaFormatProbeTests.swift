import FKUIKit
import XCTest

final class FKMediaFormatProbeTests: XCTestCase {
  func testProbeDetectsHLSFromM3U8Extension() {
    let url = URL(string: "https://cdn.example.com/stream/index.m3u8")!
    let descriptor = FKMediaFormatProbe.probe(url: url)

    XCTAssertEqual(descriptor.container, .m3u8)
    XCTAssertEqual(descriptor.suggestedEngine, .avFoundation)
    if case let .hls(onDemand) = descriptor.delivery {
      XCTAssertTrue(onDemand)
    } else {
      XCTFail("Expected HLS delivery")
    }
  }

  func testProbeDetectsLiveHLSWhenURLContainsLiveToken() {
    let url = URL(string: "https://cdn.example.com/live/channel.m3u8")!
    let descriptor = FKMediaFormatProbe.probe(url: url)

    XCTAssertTrue(descriptor.isLive)
    if case let .hls(onDemand) = descriptor.delivery {
      XCTAssertFalse(onDemand)
    } else {
      XCTFail("Expected HLS delivery")
    }
  }

  func testProbeDetectsDASHFromMPDExtension() {
    let url = URL(string: "https://cdn.example.com/manifest.mpd")!
    let descriptor = FKMediaFormatProbe.probe(url: url)

    XCTAssertEqual(descriptor.container, .mpd)
    XCTAssertEqual(descriptor.suggestedEngine, .extended)
    XCTAssertEqual(descriptor.delivery, .dash)
  }

  func testProbeDetectsRTMPAsExtendedLiveStream() {
    let url = URL(string: "rtmp://live.example.com/app/stream")!
    let descriptor = FKMediaFormatProbe.probe(url: url)

    XCTAssertEqual(descriptor.container, .flv)
    XCTAssertEqual(descriptor.delivery, .rtmp)
    XCTAssertTrue(descriptor.isLive)
    XCTAssertFalse(descriptor.allowsAVFoundation)
    XCTAssertTrue(descriptor.allowsExtended)
  }

  func testProbeUsesContentTypeWhenMIMEIndicatesMPEGURL() {
    let url = URL(string: "https://cdn.example.com/playlist")!
    let descriptor = FKMediaFormatProbe.probe(
      url: url,
      headers: ["Content-Type": "application/vnd.apple.mpegurl"]
    )

    XCTAssertEqual(descriptor.container, .m3u8)
    XCTAssertEqual(descriptor.suggestedEngine, .avFoundation)
  }

  func testProbeMapsMP4ToAVFoundationProgressiveHTTP() {
    let url = URL(string: "https://cdn.example.com/video.mp4")!
    let descriptor = FKMediaFormatProbe.probe(url: url)

    XCTAssertEqual(descriptor.container, .mp4)
    XCTAssertEqual(descriptor.suggestedEngine, .avFoundation)
    XCTAssertEqual(descriptor.delivery, .progressiveHTTP)
  }
}
