import Foundation

/// Convenience namespace for extended-engine registration (part of ``FKUIKit``).
///
/// Prefer ``FKMediaEngineRouter/registerExtendedEngineFactory(_:)``; this type exists for readable call sites.
public enum FKMediaPlayerExtended {

  /// Registers a custom extended-engine factory (e.g. FFmpeg) at app launch.
  public static func registerExtendedEngineFactory(_ factory: FKMediaExtendedEngineFactory) {
    FKMediaEngineRouter.registerExtendedEngineFactory(factory)
  }
}
