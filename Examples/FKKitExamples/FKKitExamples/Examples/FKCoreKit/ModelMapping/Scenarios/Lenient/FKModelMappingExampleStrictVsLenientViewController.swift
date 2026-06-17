import FKCoreKit
import UIKit
import Foundation
import Foundation

/// Strict vs lenient configuration on the same payload.
final class FKModelMappingExampleStrictVsLenientViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Strict vs Lenient"
    addInfoLabel("Compare .strict, .standard, .lenientAPI, and configuration presets.")
    addActionButton("Strict fails on loose JSON") { [weak self] in
      self?.runMapping("Strict") {
        do {
          _ = try FKModelMapper(configuration: .strict)
            .decode(FKModelMappingDemoProduct.self, from: FKModelMappingExampleSupport.Payload.lenientProduct)
          return "Unexpected success"
        } catch {
          return "Strict Codable failed: \(FKModelMappingExampleSupport.describe(error: error))"
        }
      }
    }
    addActionButton("Lenient succeeds") { [weak self] in
      self?.runMapping("Lenient") {
        let dictionary = try JSONSerialization.jsonObject(with: FKModelMappingExampleSupport.Payload.lenientProduct) as! [String: Any]
        let product = try FKModelMapper(configuration: .lenientAPI)
          .decode(FKModelMappingDemoLenientProduct.self, from: dictionary)
        return "Lenient price=\(product.price), quantity=\(product.quantity)"
      }
    }
    addActionButton("Preset summary") { [weak self] in
      self?.runMapping("Presets") {
        """
        .standard keyStrategy=\(FKModelMappingConfiguration.standard.keyStrategy)
        .apiDefault keyStrategy=\(FKModelMappingConfiguration.apiDefault.keyStrategy)
        .lenientAPI mode=\(FKModelMappingConfiguration.lenientAPI.mappingMode)
        .strict unknownKeys=\(FKModelMappingConfiguration.strict.unknownKeyStrategy)
        """
      }
    }
    addActionButton("FKMappingError coding path") { [weak self] in
      self?.runMapping("Error path") {
        do {
          _ = try FKModelMapper(configuration: .standard)
            .decode(FKModelMappingDemoProduct.self, from: FKModelMappingExampleSupport.Payload.strictProduct)
          return "Unexpected success"
        } catch let error as FKMappingError {
          if case let .decodingFailed(underlying, path) = error {
            return "decodingFailed path=\(path.joined(separator: ".")) underlying=\(underlying.localizedDescription)"
          }
          return error.localizedDescription
        }
      }
    }
  }
}
