import Foundation

private extension FKFileManager {
  /// Runs async `FKFileManager` work and delivers `Result` on the main actor (matches `async` overload semantics).
  func deliverResult<T: Sendable>(
    _ work: @escaping @Sendable () async throws -> T,
    completion: @escaping @Sendable (Result<T, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        completion(.success(try await work()))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }
}

public extension FKFileManager {
  /// Closure-based convenience for creating a directory.
  func createDirectory(
    at url: URL,
    intermediate: Bool = true,
    completion: @escaping @Sendable (Result<Void, FKFileManagerError>) -> Void
  ) {
    deliverResult({ try await self.createDirectory(at: url, intermediate: intermediate) }, completion: completion)
  }

  /// Closure-based convenience for deleting a file or directory.
  func removeItem(
    at url: URL,
    completion: @escaping @Sendable (Result<Void, FKFileManagerError>) -> Void
  ) {
    deliverResult({ try await self.removeItem(at: url) }, completion: completion)
  }

  /// Closure-based convenience for writing content.
  func writeContent(
    _ content: FKFileContent,
    to url: URL,
    atomically: Bool = true,
    completion: @escaping @Sendable (Result<Void, FKFileManagerError>) -> Void
  ) {
    deliverResult({ try await self.writeContent(content, to: url, atomically: atomically) }, completion: completion)
  }

  /// Closure-based convenience for reading Data.
  func readData(
    from url: URL,
    completion: @escaping @Sendable (Result<Data, FKFileManagerError>) -> Void
  ) {
    deliverResult({ try await self.readData(from: url) }, completion: completion)
  }

  /// Closure-based convenience for reading text.
  func readText(
    from url: URL,
    encoding: String.Encoding = .utf8,
    completion: @escaping @Sendable (Result<String, FKFileManagerError>) -> Void
  ) {
    deliverResult({ try await self.readText(from: url, encoding: encoding) }, completion: completion)
  }

  /// Closure-based convenience for writing codable model.
  func writeModel<T: Codable & Sendable>(
    _ model: T,
    to url: URL,
    completion: @escaping @Sendable (Result<Void, FKFileManagerError>) -> Void
  ) {
    deliverResult({ try await self.writeModel(model, to: url) }, completion: completion)
  }

  /// Closure-based convenience for reading codable model.
  func readModel<T: Codable & Sendable>(
    _ type: T.Type,
    from url: URL,
    completion: @escaping @Sendable (Result<T, FKFileManagerError>) -> Void
  ) {
    deliverResult({ try await self.readModel(type, from: url) }, completion: completion)
  }

  /// Closure-based convenience for starting a download task.
  func download(
    _ request: FKDownloadRequest,
    completion: @escaping @Sendable (Result<Int, FKFileManagerError>) -> Void
  ) {
    deliverResult({ try await self.download(request) }, completion: completion)
  }

  /// Closure-based convenience for starting an upload task.
  func upload(
    _ request: FKUploadRequest,
    completion: @escaping @Sendable (Result<Int, FKFileManagerError>) -> Void
  ) {
    deliverResult({ try await self.upload(request) }, completion: completion)
  }
}
