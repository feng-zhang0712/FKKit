import Foundation

/// Supplies parameters merged into every pluggable analytics event before upload.
public protocol FKPluggableAnalyticsCommonParametersProviding: Sendable {
  /// Returns extra parameters to merge into each event.
  func commonParameters() -> [String: String]
}

/// Uploads batched pluggable analytics events to the host backend or SDK adapter.
public protocol FKPluggableAnalyticsUploading: Sendable {
  /// Uploads a batch of events in one request or SDK call.
  func upload(batch: [FKPluggableAnalyticsEvent]) async throws
}

/// High-level tracking surface while delegating upload to ``FKPluggableAnalyticsUploading``.
public protocol FKPluggableAnalyticsTracking: AnyObject, Sendable {
  /// Registers an uploader implementation.
  func setUploader(_ uploader: (any FKPluggableAnalyticsUploading)?)

  /// Registers a common-parameters provider.
  func setCommonParametersProvider(_ provider: (any FKPluggableAnalyticsCommonParametersProviding)?)

  /// Records a page view.
  func trackPageView(_ page: String, parameters: [String: String]?)

  /// Records a click interaction.
  func trackClick(element: String, page: String?, parameters: [String: String]?)

  /// Records a custom named event.
  func trackEvent(_ name: String, parameters: [String: String]?)

  /// Forces delivery of buffered events.
  func flush() async
}
