import Foundation

/// SharePlay integration assessment hook (Phase 4). Implement when GroupActivities is available.
@MainActor
public protocol FKVideoSharePlayCoordinating: AnyObject {
  var isSharePlayActive: Bool { get }
  func startSharePlay(for item: FKVideoItem) async throws
  func endSharePlay()
}

/// Default no-op SharePlay coordinator for apps without GroupActivities entitlement.
@MainActor
public final class FKVideoSharePlayCoordinator: FKVideoSharePlayCoordinating {

  public private(set) var isSharePlayActive = false

  public init() {}

  public func startSharePlay(for item: FKVideoItem) async throws {
    _ = item
    throw FKMediaError.notImplemented(feature: "SharePlay / GroupActivities")
  }

  public func endSharePlay() {
    isSharePlayActive = false
  }
}
