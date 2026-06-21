import FKCoreKit
import UIKit
import Foundation
import Foundation

/// Property wrappers and transform registry usage.
final class FKModelMappingExamplePropertyWrappersViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Property Wrappers"
    addInfoLabel("@FKDefault, @FKLossyArray, FKIntTransform, and FKTransformRegistry.")
    addActionButton("Decode wrapper model") { [weak self] in
      self?.runMapping("Wrappers") {
        let model = try FKModelMapper(configuration: .lenientAPI)
          .decode(FKModelMappingDemoWrapperModel.self, from: FKModelMappingExampleSupport.Payload.wrapperPayload)
        return "rating=\(model.rating), note=\(model.note?.description ?? "nil"), tags=\(model.tags)"
      }
    }
    addActionButton("FKIntTransform lenient") { [weak self] in
      self?.runMapping("Int transform") {
        let transform = FKIntTransform()
        let value = try transform.transformFromJSON("42")
        return "FKIntTransform: \(value ?? -1)"
      }
    }
    addActionButton("Custom registry type") { [weak self] in
      self?.runMapping("Registry") {
        let url = try FKURLTransform().transformFromJSON("https://example.com")
        return "FKURLTransform: \(url?.absoluteString ?? "nil")"
      }
    }
  }
}
