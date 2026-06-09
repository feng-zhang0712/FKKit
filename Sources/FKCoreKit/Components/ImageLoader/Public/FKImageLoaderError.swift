import Foundation

/// Typed errors produced by ``FKImageLoader``.
public enum FKImageLoaderError: Error, Sendable, Equatable {
  /// The URL scheme is not supported in v1 (`http`, `https`, and `file` only).
  case unsupportedURLScheme(String)
  /// `targetWidth` or `targetHeight` is zero or negative.
  case invalidTargetDimensions
  /// HTTP response status code outside the configured success range.
  case httpStatus(code: Int)
  /// Underlying transport failure (timeout, connection lost, etc.).
  case network(underlyingDescription: String)
  /// Image bytes could not be decoded into a bitmap.
  case decodeFailed
  /// Bytes are present but fail integrity or format checks.
  case corruptData
  /// Detected format is not supported for static decode.
  case unsupportedFormat(String)
  /// Local file URL does not resolve to an existing file.
  case fileNotFound
  /// Local file exists but could not be read.
  case fileReadFailed
  /// Local file failed sandbox/symlink validation.
  case insecureFileURL
  /// Fast-fail reachability check reported no connectivity.
  case offline
  /// Load was cancelled before completion.
  case cancelled
  /// ``FKImageLoadOptions/cachePolicy`` is `.cacheOnly` and no cached entry exists.
  case cacheMissUnderCacheOnlyPolicy
  /// Conditional GET returned 304 but no usable disk entry exists.
  case notModifiedWithoutCache
}
