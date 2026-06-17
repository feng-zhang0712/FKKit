import FKCoreKit
import UIKit
import Foundation

/// Encode to snake_case JSON and dictionary output.
final class FKModelMappingExampleEncodingViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Encoding"
    addInfoLabel("convertToSnakeCase encoding, encodeString, and dictionary(from:).")
    addActionButton("Encode snake_case JSON") { [weak self] in
      self?.runMapping("Snake encode") {
        var config = FKModelMappingConfiguration.standard
        config.keyStrategy = .convertToSnakeCase
        let request = FKModelMappingDemoCreateUserRequest(displayName: "Encode Me", emailAddress: "encode@example.com", isActive: true)
        let json = try FKModelMapper(configuration: config).encodeString(request)
        return json
      }
    }
    addActionButton("dictionary(from:) output") { [weak self] in
      self?.runMapping("Dictionary encode") {
        let user = FKModelMappingDemoUser(id: 3, displayName: "Dict", email: "d@example.com", isActive: false)
        let dict = try FKModelMapper(configuration: .standard).dictionary(from: user)
        return "keys=\(dict.keys.sorted().joined(separator: ", "))"
      }
    }
    addActionButton("FKJSONCodec encode Data") { [weak self] in
      self?.runMapping("Codec encode") {
        let data = try FKJSONCodec(configuration: .standard).encode(
          FKModelMappingDemoUser(id: 4, displayName: "Codec", email: "c@example.com", isActive: true)
        )
        return FKModelMappingExampleSupport.prettyData(data)
      }
    }
  }
}
