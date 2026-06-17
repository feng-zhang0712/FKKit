import FKCoreKit
import UIKit
import Foundation

/// Standard Codable decode/encode round trip with ``FKModelMapper`` and ``FKJSONCodec``.
final class FKModelMappingExampleCodableBasicsViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Standard Codable"
    addInfoLabel("FKModelMapper.decode/encode with .standard configuration and FKJSONCodec.")
    addActionButton("Decode user JSON") { [weak self] in
      self?.runMapping("Decode") {
        let mapper = FKModelMapper(configuration: .standard)
        let user = try mapper.decode(FKModelMappingDemoUser.self, from: FKModelMappingExampleSupport.Payload.standardUser)
        return "User: id=\(user.id), name=\(user.displayName), active=\(user.isActive)"
      }
    }
    addActionButton("Encode round trip") { [weak self] in
      self?.runMapping("Encode") {
        let mapper = FKModelMapper(configuration: .standard)
        let user = FKModelMappingDemoUser(id: 9, displayName: "Round Trip", email: "rt@example.com", isActive: true)
        let json = try mapper.encodeString(user)
        let decoded = try mapper.decode(FKModelMappingDemoUser.self, from: json)
        return "JSON: \(json)\nDecoded id=\(decoded.id)"
      }
    }
    addActionButton("FKJSONCodec.makeDecoder()") { [weak self] in
      self?.runMapping("Codec") {
        let codec = FKJSONCodec(configuration: .standard)
        let user = try codec.decode(FKModelMappingDemoUser.self, from: FKModelMappingExampleSupport.Payload.standardUser)
        return "Codec decoded: \(user.displayName)"
      }
    }
    addActionButton("Load FKMappingFixture") { [weak self] in
      self?.runMapping("Fixture") {
        let data = try FKMappingFixture.data(named: "fixture_user")
        let user = try FKModelMapper.shared.decode(FKModelMappingDemoUser.self, from: data)
        return "Fixture user: \(user.displayName) <\(user.email)>"
      }
    }
  }
}
