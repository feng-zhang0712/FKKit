import FKCoreKit
import UIKit

/// Utilities for pairing ``FKListDelegate`` prefetch callbacks with ``FKImageLoader``.
@MainActor
public enum FKListImagePrefetchHelper {

  /// Lookup for custom payloads stored via ``FKDiffableTableViewController/setPayload(_:for:)``.
  public typealias PayloadProvider = (FKListItemID) -> FKListItemPayload?

  /// Extracts remote leading URLs from preset icon rows for the given item ids.
  public static func remoteLeadingURLs(
    for ids: [FKListItemID],
    in snapshot: FKListSnapshot
  ) -> [URL] {
    ids.compactMap { id in
      guard let item = snapshot.item(withID: id),
            case .preset(.icon(let row)) = item.kind,
            case .remoteURL(let url) = row.leading
      else { return nil }
      return url
    }
  }

  /// Collects prefetch requests from preset icon rows and ``FKListImagePrefetchProviding`` payloads.
  public static func prefetchRequests(
    for ids: [FKListItemID],
    in snapshot: FKListSnapshot,
    payloadProvider: PayloadProvider? = nil,
    presetIconTargetSize: CGSize = CGSize(width: 44, height: 44)
  ) -> [FKListImagePrefetchRequest] {
    var requests: [FKListImagePrefetchRequest] = []
    requests.reserveCapacity(ids.count * 2)
    for id in ids {
      if let item = snapshot.item(withID: id),
         case .preset(.icon(let row)) = item.kind,
         case .remoteURL(let url) = row.leading {
        requests.append(FKListImagePrefetchRequest(url: url, targetSize: presetIconTargetSize))
      }
      if let payload = payloadProvider?(id),
         let providing = payload.unwrap(FKListImagePrefetchProviding.self) {
        requests.append(contentsOf: providing.listPrefetchImageRequests)
      }
    }
    return requests
  }

  /// Prefetches images for preset icon rows and opt-in custom payloads.
  public static func prefetchImages(
    for ids: [FKListItemID],
    in snapshot: FKListSnapshot,
    payloadProvider: PayloadProvider? = nil,
    presetIconTargetSize: CGSize = CGSize(width: 44, height: 44),
    loader: FKImageLoader = .shared
  ) {
    let requests = prefetchRequests(
      for: ids,
      in: snapshot,
      payloadProvider: payloadProvider,
      presetIconTargetSize: presetIconTargetSize
    )
    guard !requests.isEmpty else { return }
    Task {
      for request in requests {
        await loader.prefetch(urls: [request.url], targetSize: request.targetSize)
      }
    }
  }

  /// Cancels in-flight prefetch for preset icon rows and opt-in custom payloads.
  public static func cancelPrefetchImages(
    for ids: [FKListItemID],
    in snapshot: FKListSnapshot,
    payloadProvider: PayloadProvider? = nil,
    presetIconTargetSize: CGSize = CGSize(width: 44, height: 44),
    loader: FKImageLoader = .shared
  ) {
    let requests = prefetchRequests(
      for: ids,
      in: snapshot,
      payloadProvider: payloadProvider,
      presetIconTargetSize: presetIconTargetSize
    )
    for request in requests {
      loader.cancelPrefetch(for: FKImageLoadRequest(url: request.url, targetSize: request.targetSize))
    }
  }

  /// Prefetches leading icon URLs for preset icon rows.
  public static func prefetchLeadingIcons(
    ids: [FKListItemID],
    in snapshot: FKListSnapshot,
    targetSize: CGSize,
    loader: FKImageLoader = .shared
  ) {
    prefetchImages(
      for: ids,
      in: snapshot,
      payloadProvider: nil,
      presetIconTargetSize: targetSize,
      loader: loader
    )
  }

  /// Cancels in-flight prefetch for leading icon URLs on preset icon rows.
  public static func cancelPrefetchLeadingIcons(
    ids: [FKListItemID],
    in snapshot: FKListSnapshot,
    targetSize: CGSize,
    loader: FKImageLoader = .shared
  ) {
    cancelPrefetchImages(
      for: ids,
      in: snapshot,
      payloadProvider: nil,
      presetIconTargetSize: targetSize,
      loader: loader
    )
  }
}
