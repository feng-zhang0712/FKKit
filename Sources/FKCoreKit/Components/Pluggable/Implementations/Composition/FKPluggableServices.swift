import Foundation

#if canImport(UIKit)
import UIKit

/// Optional composition-root template wiring production-friendly Pluggable defaults.
///
/// Prefer injecting individual protocols into feature modules rather than passing this container everywhere.
public struct FKPluggableServices: Sendable {
  /// HTTP client boundary.
  public var apiClient: any FKAPIClientProviding
  /// Typed key-value storage boundary.
  public var storage: any FKCodableStoring
  /// Authenticated session reader.
  public var session: any FKUserSessionProviding
  /// Session observer (often the same instance as ``session``).
  public var sessionObserver: any FKUserSessionObserving
  /// Build/runtime environment snapshot.
  public var environment: any FKAppEnvironmentProviding
  /// Feature-flag provider.
  public var featureFlags: any FKFeatureFlagProviding
  /// Remote configuration provider.
  public var remoteConfig: any FKRemoteConfigProviding
  /// Image loading boundary.
  public var imageLoader: any FKImageLoading
  /// Structured logging boundary.
  public var logger: any FKPluggableLogging
  /// Network reachability boundary.
  public var reachability: any FKNetworkReachabilityProviding
  /// Biometric authentication boundary.
  public var biometricAuth: any FKBiometricAuthenticating
  /// Localization boundary.
  public var localizer: any FKLocalizing

  /// Creates a service bundle with explicit dependencies.
  public init(
    apiClient: any FKAPIClientProviding,
    storage: any FKCodableStoring,
    session: any FKUserSessionProviding,
    sessionObserver: any FKUserSessionObserving,
    environment: any FKAppEnvironmentProviding,
    featureFlags: any FKFeatureFlagProviding,
    remoteConfig: any FKRemoteConfigProviding,
    imageLoader: any FKImageLoading,
    logger: any FKPluggableLogging,
    reachability: any FKNetworkReachabilityProviding,
    biometricAuth: any FKBiometricAuthenticating,
    localizer: any FKLocalizing
  ) {
    self.apiClient = apiClient
    self.storage = storage
    self.session = session
    self.sessionObserver = sessionObserver
    self.environment = environment
    self.featureFlags = featureFlags
    self.remoteConfig = remoteConfig
    self.imageLoader = imageLoader
    self.logger = logger
    self.reachability = reachability
    self.biometricAuth = biometricAuth
    self.localizer = localizer
  }

  /// Production-friendly defaults for small apps and FKKitExamples.
  ///
  /// Call **once at app launch** — each invocation creates a new ``FKNetworkReachability`` monitor.
  /// Must be called on the main actor because ``FKImageLoader/shared`` is `@MainActor`.
  @MainActor
  public static func productionDefaults() -> FKPluggableServices {
    let storageBackend = FKUserDefaultsStorage(suiteName: nil, keyPrefix: "fk.")
    let storage = FKCodableStoragePluggableAdapter(storage: storageBackend, keyPrefix: "pluggable")
    let sessionStore = FKUserSessionStore(storage: storage)
    return FKPluggableServices(
      apiClient: FKNetworkClientPluggableAdapter(),
      storage: storage,
      session: sessionStore,
      sessionObserver: sessionStore,
      environment: FKBuildTimeAppEnvironment(),
      featureFlags: FKInMemoryFeatureFlags(),
      remoteConfig: FKJSONRemoteConfigProvider(configuration: .init()),
      imageLoader: FKImageLoader.shared,
      logger: FKLoggerPluggableAdapter(),
      reachability: FKNetworkReachability(),
      biometricAuth: FKBiometricAuth.shared,
      localizer: FKI18nManager.shared
    )
  }
}

#endif
