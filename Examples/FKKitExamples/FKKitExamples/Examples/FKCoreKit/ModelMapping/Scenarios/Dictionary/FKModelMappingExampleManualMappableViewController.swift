import FKCoreKit
import UIKit
import Foundation

/// Conditional manual mapping with ``FKMappable``.
final class FKModelMappingExampleManualMappableViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Manual FKMappable"
    addInfoLabel("Merge amount_text / legacy_total and default currency in init(map:).")
    addActionButton("Decode manual order") { [weak self] in
      self?.runMapping("Manual order") {
        let order = try FKDictionaryMapper(configuration: .lenientAPI)
          .decode(FKModelMappingDemoManualOrder.self, from: FKModelMappingExampleSupport.Payload.manualMergePayload)
        return "orderID=\(order.orderID), amount=\(order.amount), currency=\(order.currency)"
      }
    }
    addActionButton("Lenient dictionary warnings") { [weak self] in
      self?.runMapping("Lenient warnings") {
        let result = try FKDictionaryMapper(configuration: .lenientAPI)
          .decodeLenient(FKModelMappingDemoManualOrder.self, from: FKModelMappingExampleSupport.Payload.manualMergePayload)
        return "amount=\(result.value.amount), warnings=\(result.warnings.count)"
      }
    }
  }
}
