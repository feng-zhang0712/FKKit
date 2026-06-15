import Foundation

/// Enqueues Pluggable analytics batches into BusinessKit's ``FKBusinessTracking`` buffer.
///
/// Use when a Pluggable analytics pipeline should share BusinessKit file buffering and flush scheduling.
/// Configure the real network/SDK uploader on ``FKBusinessKit/shared/track`` via ``FKBusinessTracking/setUploader(_:)``.
public final class FKBusinessAnalyticsPluggableUploader: FKPluggableAnalyticsUploading, @unchecked Sendable {
  /// BusinessKit tracker that receives converted events.
  private let tracker: FKBusinessTracking

  /// Creates an uploader that forwards into BusinessKit's analytics buffer.
  ///
  /// - Parameter tracker: BusinessKit tracker (default shared instance).
  public init(tracker: FKBusinessTracking = FKBusinessKit.shared.track) {
    self.tracker = tracker
  }

  /// Converts each Pluggable event into a BusinessKit custom event and enqueues it.
  ///
  /// Does not flush automatically; rely on BusinessKit timer, manual flush, or lifecycle hooks.
  public func upload(batch: [FKPluggableAnalyticsEvent]) async throws {
    for event in batch {
      var parameters = event.parameters
      parameters["pluggable_event_id"] = event.id
      tracker.trackEvent(event.name, parameters: parameters)
    }
  }
}

/// Bridges BusinessKit batched uploads to a Pluggable analytics uploader.
public final class FKBusinessAnalyticsUploadingPluggableAdapter: FKAnalyticsUploading, @unchecked Sendable {
  /// Pluggable uploader invoked after event conversion.
  private let pluggableUploader: FKPluggableAnalyticsUploading

  /// Creates an adapter for ``FKBusinessTracking/setUploader(_:)``.
  ///
  /// - Parameter pluggableUploader: Pluggable-side upload implementation.
  public init(pluggableUploader: FKPluggableAnalyticsUploading) {
    self.pluggableUploader = pluggableUploader
  }

  /// Uploads a BusinessKit batch through the Pluggable uploader.
  @available(iOS 13.0, *)
  public func upload(batch: [FKAnalyticsEvent]) async throws {
    let converted = batch.map { event in
      FKPluggableAnalyticsEvent(
        id: event.id,
        name: event.name,
        timestamp: event.timestamp,
        parameters: event.parameters.merging(["event_type": event.type.rawValue]) { current, _ in current }
      )
    }
    try await pluggableUploader.upload(batch: converted)
  }
}
