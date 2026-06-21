import FKCoreKit
import UIKit
import Foundation

/// Pagination templates and shared mapper utilities.
final class FKModelMappingExamplePaginationTemplatesViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pagination & Utilities"
    addInfoLabel("FKPage, FKListResponse, FKModelMapper.shared, and FKNoOpMappingLogger.")
    addActionButton("Decode FKPage") { [weak self] in
      self?.runMapping("FKPage") {
        let page = try FKModelMapper(configuration: .apiDefault)
          .decode(FKPage<FKModelMappingDemoUser>.self, from: FKModelMappingExampleSupport.Payload.pagePayload)
        return "items=\(page.items.count), total=\(page.total), page=\(page.page ?? -1), size=\(page.pageSize ?? -1)"
      }
    }
    addActionButton("Decode FKListResponse") { [weak self] in
      self?.runMapping("FKListResponse") {
        let response = try FKModelMapper(configuration: .standard)
          .decode(FKListResponse<FKModelMappingDemoUser>.self, from: FKModelMappingExampleSupport.Payload.listResponsePayload)
        return "list=\(response.list.count), count=\(response.count)"
      }
    }
    addActionButton("FKModelMapper.shared (.lenientAPI)") { [weak self] in
      self?.runMapping("Shared mapper") {
        let user = try FKModelMapper.shared.decode(FKModelMappingDemoUser.self, from: FKModelMappingExampleSupport.Payload.standardUser)
        return "shared decoded: \(user.displayName)"
      }
    }
    addActionButton("Custom FKMappingLogging") { [weak self] in
      self?.runMapping("Logging") {
        final class DemoLogger: FKMappingLogging, @unchecked Sendable {
          private let lock = NSLock()
          private var lines: [String] = []
          func didDecode(type: Any.Type, path: String?, duration: TimeInterval) {
            lock.lock()
            lines.append("decode \(type) in \(String(format: "%.3f", duration))s")
            lock.unlock()
          }
          func didFail(error: FKMappingError, preview: Data?) {
            lock.lock()
            lines.append("fail \(error.localizedDescription)")
            lock.unlock()
          }
          func snapshot() -> String {
            lock.lock()
            defer { lock.unlock() }
            return lines.joined(separator: "\n")
          }
        }
        let logger = DemoLogger()
        _ = try FKModelMapper(configuration: .standard, logger: logger)
          .decode(FKModelMappingDemoUser.self, from: FKModelMappingExampleSupport.Payload.standardUser)
        return logger.snapshot()
      }
    }
  }
}
