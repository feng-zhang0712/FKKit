import FKUIKit
import XCTest

final class FKMediaEngineRouterTests: XCTestCase {
  private func makeDescriptor(
    suggestedEngine: FKMediaEngineKind = .avFoundation,
    allowsAVFoundation: Bool = true,
    allowsExtended: Bool = false
  ) -> FKMediaFormatDescriptor {
    FKMediaFormatDescriptor(
      container: .mp4,
      mediaType: .video,
      suggestedEngine: suggestedEngine,
      delivery: .progressiveHTTP,
      isLive: false,
      allowsAVFoundation: allowsAVFoundation,
      allowsExtended: allowsExtended
    )
  }

  func testAutomaticPrefersSuggestedAVFoundationWhenAllowed() throws {
    let descriptor = makeDescriptor(suggestedEngine: .avFoundation, allowsAVFoundation: true, allowsExtended: true)

    let engine = try FKMediaEngineRouter.selectEngine(descriptor: descriptor, policy: .default)

    XCTAssertEqual(engine, .avFoundation)
  }

  func testAutomaticFallsBackToExtendedWhenAVIsDisallowed() throws {
    let descriptor = makeDescriptor(suggestedEngine: .avFoundation, allowsAVFoundation: false, allowsExtended: true)

    let engine = try FKMediaEngineRouter.selectEngine(descriptor: descriptor, policy: .default)

    XCTAssertEqual(engine, .extended)
  }

  func testPreferredAVFoundationThrowsWhenUnsupported() {
    let descriptor = makeDescriptor(allowsAVFoundation: false, allowsExtended: true)

    XCTAssertThrowsError(
      try FKMediaEngineRouter.selectEngine(
        descriptor: descriptor,
        policy: FKMediaEnginePolicy(preferredEngine: .avFoundation)
      )
    ) { error in
      guard case FKMediaError.unsupportedFormat = error else {
        return XCTFail("Expected unsupportedFormat, got \(error)")
      }
    }
  }

  func testPreferredExtendedThrowsWhenUnsupported() {
    let descriptor = makeDescriptor(allowsAVFoundation: true, allowsExtended: false)

    XCTAssertThrowsError(
      try FKMediaEngineRouter.selectEngine(
        descriptor: descriptor,
        policy: FKMediaEnginePolicy(preferredEngine: .extended)
      )
    ) { error in
      guard case FKMediaError.unsupportedFormat = error else {
        return XCTFail("Expected unsupportedFormat, got \(error)")
      }
    }
  }

  func testAutomaticThrowsWhenNeitherEngineIsAllowed() {
    let descriptor = makeDescriptor(allowsAVFoundation: false, allowsExtended: false)

    XCTAssertThrowsError(
      try FKMediaEngineRouter.selectEngine(descriptor: descriptor, policy: .default)
    ) { error in
      guard case FKMediaError.unsupportedFormat = error else {
        return XCTFail("Expected unsupportedFormat, got \(error)")
      }
    }
  }
}
