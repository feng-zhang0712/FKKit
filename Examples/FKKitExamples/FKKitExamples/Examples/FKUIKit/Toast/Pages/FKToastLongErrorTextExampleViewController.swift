import FKUIKit
import UIKit

/// Demonstrates default text limits when server errors return long, noisy messages.
final class FKToastLongErrorTextExampleViewController: FKToastExampleBaseViewController {
  private enum Mode: Int, CaseIterable {
    case limited
    case unlimited

    var title: String {
      switch self {
      case .limited: "Limited (default)"
      case .unlimited: "Unlimited"
      }
    }
  }

  private let modeControl = UISegmentedControl(items: Mode.allCases.map(\.title))
  private let longAPIError = """
  org.apache.ibatis.exceptions.PersistenceException: \
  ### Error querying database. Cause: com.kingbase8.util.KSQLException: ERROR: column "F_WORKS_ID" does not exist \
  ### SQL: SELECT t1.F_ID, t1.F_WORKS_ID, t1.F_TITLE FROM works t1 LEFT JOIN user_works uw ON t1.F_ID = uw.works_id \
  ### Cause: com.kingbase8.util.KSQLException: ERROR: column "F_WORKS_ID" does not exist
  """

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Long Error Text"

    modeControl.selectedSegmentIndex = Mode.limited.rawValue
    modeControl.addAction(UIAction { [weak self] _ in self?.showToast() }, for: .valueChanged)

    contentStack.addArrangedSubview(
      FKToastExampleUI.section(
        title: "Text limits",
        description: "Default limits clip noisy API errors to three lines and 120 characters. Choose Unlimited to compare legacy behavior.",
        body: modeControl
      )
    )
    contentStack.addArrangedSubview(
      FKToastExampleUI.button("Show error toast") { [weak self] in
        self?.showToast()
      }
    )
  }

  private func showToast() {
    let mode = Mode(rawValue: modeControl.selectedSegmentIndex) ?? .limited
    var configuration = FKToastConfiguration(kind: .toast, style: .error, position: .center, duration: 8)
    if mode == .unlimited {
      configuration.textLimits = FKToastTextLimitsConfiguration.unlimited
    }
    FKToast.show(longAPIError, configuration: configuration)
  }
}
