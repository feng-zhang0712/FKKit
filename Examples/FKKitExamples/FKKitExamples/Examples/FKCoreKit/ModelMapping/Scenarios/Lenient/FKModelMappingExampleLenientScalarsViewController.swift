import FKCoreKit
import UIKit
import Foundation

/// Loose scalar parsing with ``FKModelMappingConfiguration/lenientAPI``.
final class FKModelMappingExampleLenientScalarsViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Lenient Scalars"
    addInfoLabel("String numbers, numeric booleans, and empty-string nil normalization.")
    addActionButton("Decode lenient product") { [weak self] in
      self?.runMapping("Lenient decode") {
        let dictionary = try JSONSerialization.jsonObject(with: FKModelMappingExampleSupport.Payload.lenientProduct) as! [String: Any]
        let product = try FKModelMapper(configuration: .lenientAPI)
          .decode(FKModelMappingDemoLenientProduct.self, from: dictionary)
        return """
        sku=\(product.sku)
        price=\(product.price)
        quantity=\(product.quantity)
        note=\(product.note?.description ?? "nil")
        optionalTag=\(product.optionalTag?.description ?? "nil")
        """
      }
    }
    addActionButton("Dictionary path with FKMap") { [weak self] in
      self?.runMapping("FKMap") {
        let map = FKMap.root(
          try JSONSerialization.jsonObject(with: FKModelMappingExampleSupport.Payload.lenientProduct) as! [String: Any],
          configuration: .lenientAPI
        )
        let price = try map.value("price", as: Double.self)
        let quantity = try map.value("quantity", as: Int.self)
        return "map.price=\(price), map.quantity=\(quantity)"
      }
    }
    addActionButton("decodeLenient with warnings API") { [weak self] in
      self?.runMapping("Warnings") {
        let dictionary = try JSONSerialization.jsonObject(with: FKModelMappingExampleSupport.Payload.lenientProduct) as! [String: Any]
        let result = try FKDictionaryMapper(configuration: .lenientAPI)
          .decodeLenient(FKModelMappingDemoLenientProduct.self, from: dictionary)
        return "value sku=\(result.value.sku), warnings=\(result.warnings.count)"
      }
    }
  }
}
