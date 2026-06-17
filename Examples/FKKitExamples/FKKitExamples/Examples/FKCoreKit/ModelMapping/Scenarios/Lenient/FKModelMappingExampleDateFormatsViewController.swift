import FKCoreKit
import UIKit
import Foundation

/// ISO-8601, epoch seconds, and formatted date strategies.
final class FKModelMappingExampleDateFormatsViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Date Formats"
    addInfoLabel("FKDateDecodingStrategy presets applied through FKJSONCodec.")
    addActionButton("ISO-8601 decode") { [weak self] in
      self?.runMapping("ISO8601") {
        let mapper = FKModelMapper(configuration: .apiDefault)
        let event = try mapper.decode(FKModelMappingDemoDateEvent.self, from: FKModelMappingExampleSupport.Payload.dateEventISO)
        return "ISO event: \(event.title) @ \(event.startsAt)"
      }
    }
    addActionButton("Seconds since 1970") { [weak self] in
      self?.runMapping("Epoch seconds") {
        var config = FKModelMappingConfiguration.apiDefault
        config.dateDecoding = .secondsSince1970
        let event = try FKModelMapper(configuration: config)
          .decode(FKModelMappingDemoDateEvent.self, from: FKModelMappingExampleSupport.Payload.dateEventSeconds)
        return "Epoch event: \(event.title) @ \(event.startsAt)"
      }
    }
    addActionButton("Custom formatted date") { [weak self] in
      self?.runMapping("Formatted") {
        var config = FKModelMappingConfiguration.standard
        config.dateDecoding = .formatted(FKDateFormatConfiguration(format: "yyyy-MM-dd"))
        let payload = Data("{\"title\":\"Birthday\",\"startsAt\":\"2026-06-17\"}".utf8)
        let event = try FKModelMapper(configuration: config).decode(FKModelMappingDemoDateEvent.self, from: payload)
        return "Formatted: \(event.startsAt)"
      }
    }
    addActionButton("FKDateTransform manual") { [weak self] in
      self?.runMapping("Transform") {
        let transform = FKDateTransform(decoding: .iso8601, encoding: .iso8601)
        let date = try transform.transformFromJSON("2026-06-17T08:00:00Z")
        return "Transform date: \(date?.description ?? "nil")"
      }
    }
  }
}
