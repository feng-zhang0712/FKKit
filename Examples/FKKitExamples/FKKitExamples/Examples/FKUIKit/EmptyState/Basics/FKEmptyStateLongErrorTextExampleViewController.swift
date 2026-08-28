import FKUIKit
import UIKit

/// Demonstrates ``FKEmptyStateTextLimitsConfiguration`` when API errors return long, noisy messages.
final class FKEmptyStateLongErrorTextExampleViewController: UIViewController {
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

  private let container = UIView()
  private let modeControl = UISegmentedControl(items: Mode.allCases.map(\.title))
  private let longAPIError = """
  org.apache.ibatis.exceptions.PersistenceException: \
  ### Error querying database. Cause: java.sql.SQLSyntaxErrorException: \
  Unknown column 't1.topic_id' in 'on clause' \
  ### The error may exist in com/jnetdata/msp/custom/mapper/TopicCustomMapper.java (best guess) \
  ### The error may involve defaultParameterMap \
  ### The error occurred while setting parameters \
  ### SQL: SELECT COUNT(1) FROM topic t1 LEFT JOIN user_topic ut ON t1.id = ut.topic_id WHERE ut.user_id = ? \
  ### Cause: java.sql.SQLSyntaxErrorException: Unknown column 't1.topic_id' in 'on clause'
  """

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Long Error Text"
    view.backgroundColor = .systemBackground

    modeControl.selectedSegmentIndex = Mode.limited.rawValue
    modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

    let stack = UIStackView(arrangedSubviews: [modeControl, container])
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    applyCurrentMode()
  }

  @objc private func modeChanged() {
    applyCurrentMode()
  }

  private func applyCurrentMode() {
    let mode = Mode(rawValue: modeControl.selectedSegmentIndex) ?? .limited
    var model = FKEmptyStateConfiguration.scenario(.loadFailed)
    model.content.description = longAPIError

    switch mode {
    case .limited:
      model.presentation.textLimits = FKEmptyStateTextLimitsConfiguration()
    case .unlimited:
      model.presentation.textLimits = .unlimited
    }

    container.fk_applyEmptyState(model) { [weak self] _ in
      self?.applyCurrentMode()
    }
  }
}
