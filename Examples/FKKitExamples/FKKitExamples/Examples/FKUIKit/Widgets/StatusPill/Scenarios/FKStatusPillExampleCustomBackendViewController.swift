import FKUIKit
import UIKit

final class FKStatusPillExampleCustomBackendViewController: FKStatusPillExampleScrollViewController {

  private enum BackendOrderState: String, CaseIterable {
    case awaitingFulfillment = "AWAITING_FULFILLMENT"
    case customsHold = "CUSTOMS_HOLD"
    case returnedToSender = "RETURNED_TO_SENDER"

    func pillStyle() -> FKStatusPillStyle {
      switch self {
      case .awaitingFulfillment:
        .custom(FKStatusPillCustomAppearance(
          backgroundColor: UIColor.systemIndigo.withAlphaComponent(0.14),
          foregroundColor: .systemIndigo
        ))
      case .customsHold:
        .custom(FKStatusPillCustomAppearance(
          backgroundColor: UIColor.systemYellow.withAlphaComponent(0.22),
          foregroundColor: UIColor(red: 0.55, green: 0.45, blue: 0.05, alpha: 1)
        ))
      case .returnedToSender:
        .custom(FKStatusPillCustomAppearance(
          backgroundColor: UIColor.systemPurple.withAlphaComponent(0.14),
          foregroundColor: .systemPurple,
          dotColor: .systemPurple
        ))
      }
    }

    var displayTitle: String {
      switch self {
      case .awaitingFulfillment: "Awaiting fulfillment"
      case .customsHold: "Customs hold"
      case .returnedToSender: "Returned"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom backend enum"

    let box = FKStatusPillExampleSupport.sectionContainer(title: "Host mapping pattern")
    box.addArrangedSubview(FKStatusPillExampleSupport.caption(
      "Map server enums to FKStatusPillStyle.custom(_:) when presets do not fit. Preset semantics remain available via FKWidgetStatusColorTokens for common paths."
    ))

    BackendOrderState.allCases.forEach { state in
      let pill = FKStatusPillExampleSupport.makePill(
        title: state.displayTitle,
        style: state.pillStyle(),
        showsDot: state == .returnedToSender
      )
      box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: state.rawValue, pill: pill))
    }

    contentStack.addArrangedSubview(box)
  }
}
