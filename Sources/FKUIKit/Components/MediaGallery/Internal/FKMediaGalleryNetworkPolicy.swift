import Network

/// Cached reachability for gallery video autoplay policy checks.
@MainActor
final class FKMediaGalleryReachabilityMonitor {
  static let shared = FKMediaGalleryReachabilityMonitor()

  private(set) var isOnWiFi = false
  private let monitor = NWPathMonitor()
  private var isStarted = false

  private init() {}

  func startIfNeeded() {
    guard !isStarted else { return }
    isStarted = true
    monitor.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        self?.isOnWiFi = path.status == .satisfied && path.usesInterfaceType(.wifi)
      }
    }
    monitor.start(queue: .main)
  }
}

/// Autoplay gating from gallery video configuration.
enum FKMediaGalleryNetworkPolicy {
  @MainActor
  static func allowsAutoplay(for policy: FKMediaGalleryAutoplayPolicy) -> Bool {
    FKMediaGalleryReachabilityMonitor.shared.startIfNeeded()
    switch policy {
    case .always:
      return true
    case .never:
      return false
    case .wifiOnly:
      return FKMediaGalleryReachabilityMonitor.shared.isOnWiFi
    }
  }
}
