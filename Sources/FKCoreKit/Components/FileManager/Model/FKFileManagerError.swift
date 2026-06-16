import Foundation

/// Unified error type for FKFileManager file and transfer operations.
public enum FKFileManagerError: Error, Sendable, Equatable {
  /// Target path does not exist.
  case fileNotFound(path: String)
  /// Target path already exists.
  case fileAlreadyExists(path: String)
  /// URL is not valid for the requested operation.
  case invalidURL(String)
  /// Network transfer failed.
  case transferFailed(String)
  /// Response content is invalid for transfer handling.
  case invalidResponse
  /// Available disk space is below required bytes.
  case insufficientDiskSpace(required: Int64, available: Int64)
  /// ZIP APIs are unavailable on current platform version.
  case zipUnavailable
  /// ZIP archive is corrupted or unreadable.
  case zipCorrupted(archivePath: String)
  /// ZIP entry path escapes the destination directory (zip slip).
  case zipEntryPathUnsafe(entry: String)
  /// ZIP operation failed with a descriptive message.
  case zipOperationFailed(message: String)
  /// Unknown wrapped error.
  case unknown(String)
}

extension FKFileManagerError {
  /// Maps Foundation / POSIX errors from `FileManager` operations into structured cases when possible.
  static func mappingFileOperation(_ error: Error, path: String) -> FKFileManagerError {
    let ns = error as NSError
    if ns.domain == NSCocoaErrorDomain {
      switch ns.code {
      case NSFileReadNoSuchFileError, NSFileNoSuchFileError:
        return .fileNotFound(path: path)
      case NSFileWriteFileExistsError:
        return .fileAlreadyExists(path: path)
      default:
        break
      }
    }
    if ns.domain == NSPOSIXErrorDomain, ns.code == POSIXError.ENOENT.rawValue {
      return .fileNotFound(path: path)
    }
    if ns.domain == NSPOSIXErrorDomain, ns.code == POSIXError.EEXIST.rawValue {
      return .fileAlreadyExists(path: path)
    }
    return .unknown(error.localizedDescription)
  }
}

extension FKFileManagerError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case let .fileNotFound(path):
      return FKI18n.format("fkcore.file.error.file_not_found", path)
    case let .fileAlreadyExists(path):
      return FKI18n.format("fkcore.file.error.file_already_exists", path)
    case let .invalidURL(value):
      return FKI18n.format("fkcore.file.error.invalid_url", value)
    case let .transferFailed(message):
      return FKI18n.format("fkcore.file.error.transfer_failed", message)
    case .invalidResponse:
      return FKI18n.string("fkcore.file.error.invalid_response")
    case let .insufficientDiskSpace(required, available):
      return FKI18n.format("fkcore.file.error.insufficient_disk_space", required, available)
    case .zipUnavailable:
      return FKI18n.string("fkcore.file.error.zip_unavailable")
    case let .zipCorrupted(archivePath):
      return FKI18n.format("fkcore.file.error.zip_corrupted", archivePath)
    case let .zipEntryPathUnsafe(entry):
      return FKI18n.format("fkcore.file.error.zip_entry_path_unsafe", entry)
    case let .zipOperationFailed(message):
      return FKI18n.format("fkcore.file.error.zip_operation_failed", message)
    case let .unknown(message):
      return FKI18n.format("fkcore.file.error.unknown", message)
    }
  }
}
