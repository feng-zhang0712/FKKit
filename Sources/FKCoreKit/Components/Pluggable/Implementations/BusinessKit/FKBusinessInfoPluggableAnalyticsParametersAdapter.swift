import Foundation

/// Supplies BusinessKit device/app fields through ``FKPluggableAnalyticsCommonParametersProviding``.
///
/// Use in Pluggable DI graphs so analytics uploaders share the same common keys as ``FKBusinessAnalyticsTracker``.
public final class FKBusinessInfoPluggableAnalyticsParametersAdapter: FKPluggableAnalyticsCommonParametersProviding,
  @unchecked Sendable
{
  /// Source of bundle, version, channel, and device metadata.
  private let infoProvider: FKBusinessInfoProviding

  /// Creates an adapter over a BusinessKit info provider.
  ///
  /// - Parameter infoProvider: Info provider (default shared instance).
  public init(infoProvider: FKBusinessInfoProviding = FKBusinessKit.shared.info) {
    self.infoProvider = infoProvider
  }

  /// Returns standard BusinessKit analytics common parameters.
  public func commonParameters() -> [String: String] {
    FKBusinessAnalyticsCommonParameters.standard(from: infoProvider)
  }
}

/// Bridges a Pluggable common-parameters provider into ``FKAnalyticsCommonParametersProviding``.
public final class FKBusinessAnalyticsCommonParametersPluggableAdapter: FKAnalyticsCommonParametersProviding,
  @unchecked Sendable
{
  /// Underlying Pluggable provider.
  private let provider: FKPluggableAnalyticsCommonParametersProviding

  /// Creates an adapter for ``FKBusinessTracking/setCommonParametersProvider(_:)``.
  ///
  /// - Parameter provider: Pluggable common-parameters source.
  public init(provider: FKPluggableAnalyticsCommonParametersProviding) {
    self.provider = provider
  }

  /// Forwards parameters from the Pluggable provider.
  public func commonParameters() -> [String: String] {
    provider.commonParameters()
  }
}
