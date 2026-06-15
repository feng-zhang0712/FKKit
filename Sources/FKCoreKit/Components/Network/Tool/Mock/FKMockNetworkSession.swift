import Foundation

/// Registry that associates mock sessions with URLProtocol stub handlers.
final class FKMockURLProtocolRegistry: @unchecked Sendable {
  static let shared = FKMockURLProtocolRegistry()

  private var sessions: [String: FKMockNetworkSession] = [:]
  private let lock = NSLock()

  func register(id: String, session: FKMockNetworkSession) {
    lock.lock()
    sessions[id] = session
    lock.unlock()
  }

  func unregister(id: String) {
    lock.lock()
    sessions.removeValue(forKey: id)
    lock.unlock()
  }

  func session(for request: URLRequest) -> FKMockNetworkSession? {
    guard let marker = request.value(forHTTPHeaderField: FKMockNetworkSession.sessionHeaderKey) else {
      return nil
    }
    lock.lock()
    defer { lock.unlock() }
    return sessions[marker]
  }
}

/// URLProtocol used by ``FKMockNetworkSession`` to return canned responses.
final class FKMockURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool {
    FKMockURLProtocolRegistry.shared.session(for: request) != nil
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let client, let session = FKMockURLProtocolRegistry.shared.session(for: request) else {
      client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
      return
    }

    let work = { [weak self] in
      guard let self else { return }
      if let error = session.errorStub {
        client.urlProtocol(self, didFailWithError: error)
        return
      }

      guard let url = request.url else {
        client.urlProtocol(self, didFailWithError: NetworkError.invalidURL)
        return
      }

      let stub = session.stubbedResponses[url] ?? session.stubbedResponses.first { $0.key.path == url.path }?.value
      guard let stub else {
        client.urlProtocol(self, didFailWithError: NetworkError.noData)
        return
      }

      client.urlProtocol(self, didReceive: stub.1, cacheStoragePolicy: .notAllowed)
      client.urlProtocol(self, didLoad: stub.0)
      client.urlProtocolDidFinishLoading(self)
    }

    if session.delay > 0 {
      DispatchQueue.global().asyncAfter(deadline: .now() + session.delay, execute: work)
    } else {
      work()
    }
  }

  override func stopLoading() {}
}

/// Mock transport for integration tests and Examples.
///
/// - Important: Intended for testing and demo scenarios only; not a production transport.
public final class FKMockNetworkSession: NetworkSession, @unchecked Sendable {
  /// Header used to route requests to the owning mock session instance.
  static let sessionHeaderKey = "X-FK-Mock-Session-ID"

  /// Canned responses keyed by request URL.
  public var stubbedResponses: [URL: (Data, HTTPURLResponse)] = [:]
  /// Artificial response delay.
  public var delay: TimeInterval = 0
  /// Optional transport error returned for every request.
  public var errorStub: Error?

  private let session: URLSession
  private let sessionID: String

  /// Creates a mock session backed by a private `URLSession` and `URLProtocol`.
  public init() {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [FKMockURLProtocol.self]
    session = URLSession(configuration: configuration)
    sessionID = UUID().uuidString
    FKMockURLProtocolRegistry.shared.register(id: sessionID, session: self)
  }

  deinit {
    FKMockURLProtocolRegistry.shared.unregister(id: sessionID)
  }

  private func tagged(_ request: URLRequest) -> URLRequest {
    var tagged = request
    tagged.setValue(sessionID, forHTTPHeaderField: Self.sessionHeaderKey)
    return tagged
  }

  /// Creates a data task that resolves against ``stubbedResponses``.
  public func dataTask(
    with request: URLRequest,
    completionHandler: @escaping DataTaskCompletion
  ) -> URLSessionDataTask {
    session.dataTask(with: tagged(request), completionHandler: completionHandler)
  }

  /// Creates an upload task that resolves against ``stubbedResponses``.
  public func uploadTask(
    with request: URLRequest,
    fromFile fileURL: URL,
    completionHandler: @escaping DataTaskCompletion
  ) -> URLSessionUploadTask {
    session.uploadTask(with: tagged(request), fromFile: fileURL, completionHandler: completionHandler)
  }

  /// Creates a download task that resolves against ``stubbedResponses``.
  public func downloadTask(with request: URLRequest) -> URLSessionDownloadTask {
    session.downloadTask(with: tagged(request))
  }

  /// Creates a resumable download task that resolves against ``stubbedResponses``.
  public func downloadTask(withResumeData resumeData: Data) -> URLSessionDownloadTask {
    session.downloadTask(withResumeData: resumeData)
  }
}
