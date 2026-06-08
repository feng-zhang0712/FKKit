import FKCoreKit
import UIKit

/// Maps loader errors to view failure reasons.
enum FKImageViewFailureMapper {
  static func reason(from error: Error) -> FKImageViewFailureReason {
    if error is CancellationError {
      return .cancelled
    }
    if let loaderError = error as? FKImageLoaderError {
      switch loaderError {
      case .offline:
        return .offline
      case .cancelled:
        return .cancelled
      case .decodeFailed, .corruptData, .unsupportedFormat:
        return .decode
      default:
        return .network
      }
    }
    return .network
  }
}

/// Builds ``FKImageLoadRequest`` values and resolves cache previews.
@MainActor
enum FKImageViewRequestFactory {
  static func makeRequest(
    url: URL,
    targetSizePolicy: FKImageViewTargetSizePolicy,
    bounds: CGRect,
    screenScale: CGFloat,
    cacheKey: String? = nil
  ) -> FKImageLoadRequest {
    switch targetSizePolicy {
    case .none:
      return FKImageLoadRequest(url: url, cacheKey: cacheKey)
    case .explicit(let size):
      return FKImageLoadRequest(url: url, targetSize: size, cacheKey: cacheKey)
    case .automaticFromBounds:
      let pixelWidth = Double(bounds.width * screenScale)
      let pixelHeight = Double(bounds.height * screenScale)
      guard pixelWidth > 0, pixelHeight > 0 else {
        return FKImageLoadRequest(url: url, cacheKey: cacheKey)
      }
      return FKImageLoadRequest(
        url: url,
        targetWidth: pixelWidth,
        targetHeight: pixelHeight,
        cacheKey: cacheKey
      )
    }
  }

  static func makeRequest(from identity: FKImageViewLoadCoordinator.Identity, cacheKey: String?) -> FKImageLoadRequest {
    FKImageLoadRequest(
      url: identity.url,
      targetWidth: identity.targetWidth,
      targetHeight: identity.targetHeight,
      cacheKey: cacheKey
    )
  }

  static func cachedPreview(
    for request: FKImageLoadRequest,
    loader: any FKImageLoading,
    enabled: Bool
  ) -> UIImage? {
    guard enabled else { return nil }
    if let fkLoader = loader as? FKImageLoader {
      return fkLoader.cachedImage(for: request)
    }
    if let caching = loader as? FKImageCaching {
      return caching.cachedImage(forKey: request.resolvedCacheKey)
    }
    return nil
  }
}

/// Tracks in-flight loads with identity tokens for cell reuse safety.
final class FKImageViewLoadCoordinator {
  struct Identity: Equatable {
    let token: UUID
    let url: URL
    let cacheKey: String
    let targetWidth: Double?
    let targetHeight: Double?
  }

  private(set) var identity: Identity?
  private var loadTask: Task<Void, Never>?

  deinit {
    loadTask?.cancel()
  }

  func cancel() {
    loadTask?.cancel()
    loadTask = nil
  }

  func resetIdentity() {
    identity = nil
    cancel()
  }

  @MainActor
  func start(
    request: FKImageLoadRequest,
    loader: any FKImageLoading,
    options: FKImageLoadOptions,
    onState: @escaping @MainActor (FKImageViewState) -> Void,
    onSuccess: @escaping @MainActor (UIImage, Identity) -> Void,
    onFailure: @escaping @MainActor (FKImageViewFailureReason, Identity) -> Void
  ) {
    cancel()
    let token = UUID()
    let newIdentity = Identity(
      token: token,
      url: request.url,
      cacheKey: request.resolvedCacheKey,
      targetWidth: request.targetWidth,
      targetHeight: request.targetHeight
    )
    identity = newIdentity
    onState(.loading)

    loadTask = Task { @MainActor in
      do {
        let image: UIImage
        if let fkLoader = loader as? FKImageLoader {
          image = try await fkLoader.loadImage(for: request, options: options)
        } else {
          image = try await loader.loadImage(for: request)
        }
        guard !Task.isCancelled else {
          if self.identity == newIdentity {
            self.identity = nil
          }
          return
        }
        guard self.identity == newIdentity else {
          FKImageViewLogging.debug("Discarded stale success for \(newIdentity.url.absoluteString)")
          return
        }
        onSuccess(image, newIdentity)
        if self.identity == newIdentity {
          self.identity = nil
        }
      } catch {
        guard !Task.isCancelled else {
          if self.identity == newIdentity {
            self.identity = nil
          }
          return
        }
        guard self.identity == newIdentity else {
          FKImageViewLogging.debug("Discarded stale failure for \(newIdentity.url.absoluteString)")
          return
        }
        let reason = FKImageViewFailureMapper.reason(from: error)
        if reason == .cancelled {
          if self.identity == newIdentity {
            self.identity = nil
          }
          return
        }
        onFailure(reason, newIdentity)
        if self.identity == newIdentity {
          self.identity = nil
        }
      }
    }
  }

  @MainActor
  func cancelLoad(loader: any FKImageLoading, request: FKImageLoadRequest) {
    loader.cancelLoad(for: request)
    resetIdentity()
  }
}
