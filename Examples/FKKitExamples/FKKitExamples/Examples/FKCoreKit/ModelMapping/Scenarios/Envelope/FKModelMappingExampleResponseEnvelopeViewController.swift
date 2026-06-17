import FKCoreKit
import UIKit
import Foundation

/// Response envelope unwrap and business code validation.
final class FKModelMappingExampleResponseEnvelopeViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Response Envelope"
    addInfoLabel("FKResponseEnvelopeProcessor, decodeEnvelope, and success-flag preset.")
    addActionButton("decodeEnvelope success") { [weak self] in
      self?.runMapping("decodeEnvelope") {
        var config = FKModelMappingConfiguration.lenientAPI
        config.envelope = .standard
        let user = try FKModelMapper(configuration: config)
          .decodeEnvelope(FKModelMappingDemoUser.self, from: FKModelMappingExampleSupport.Payload.envelopeSuccess)
        return "Envelope user: \(user.displayName)"
      }
    }
    addActionButton("FKResponseEnvelopeProcessor") { [weak self] in
      self?.runMapping("Processor") {
        let processor = FKResponseEnvelopeProcessor(configuration: .standard)
        let result = try processor.process(data: FKModelMappingExampleSupport.Payload.envelopeSuccess)
        let user = try FKModelMapper(configuration: .standard).decode(FKModelMappingDemoUser.self, from: result.payload)
        return "payload bytes=\(result.payload.count), code=\(result.businessCode ?? -1), user=\(user.displayName)"
      }
    }
    addActionButton("Success-flag envelope (.successFlag)") { [weak self] in
      self?.runMapping("Success flag") {
        let processor = FKResponseEnvelopeProcessor(configuration: .successFlag)
        let result = try processor.process(data: FKModelMappingExampleSupport.Payload.successFlagEnvelope)
        let page = try FKModelMapper(configuration: .standard).decode(FKListResponse<FKModelMappingDemoUser>.self, from: result.payload)
        return "list count=\(page.count), first=\(page.list.first?.displayName ?? "-")"
      }
    }
    addActionButton("Business failure") { [weak self] in
      self?.runMapping("Business fail") {
        do {
          _ = try FKResponseEnvelopeProcessor(configuration: .standard)
            .process(data: FKModelMappingExampleSupport.Payload.envelopeBusinessFailure)
          return "Unexpected success"
        } catch let error as FKMappingError {
          if case let .businessFailure(code, message, _) = error {
            let network = error.asNetworkError()
            return "businessFailure code=\(code), msg=\(message ?? "-")\nasNetworkError=\(network.localizedDescription)"
          }
          throw error
        }
      }
    }
  }
}
