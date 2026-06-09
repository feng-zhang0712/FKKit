import UIKit

enum FKFlowIconResolver {
  static func image(
    for icon: FKFlowStepIcon?,
    state: FKFlowStepState,
    stepIndex: Int,
    configuration: UIImage.SymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
  ) -> UIImage? {
    if let icon {
      return resolveExplicit(icon: icon, configuration: configuration)
    }
    return defaultImage(for: state, stepIndex: stepIndex, configuration: configuration)
  }

  private static func resolveExplicit(icon: FKFlowStepIcon, configuration: UIImage.SymbolConfiguration) -> UIImage? {
    switch icon {
    case .number(let value):
      return nil
    case .systemName(let name):
      return UIImage(systemName: name, withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
    case .imageAsset(let name, let bundle):
      return UIImage(named: name, in: bundle, with: nil)?.withRenderingMode(.alwaysTemplate)
    case .template(let image):
      return image.withRenderingMode(.alwaysTemplate)
    case .none:
      return nil
    }
  }

  private static func defaultImage(
    for state: FKFlowStepState,
    stepIndex: Int,
    configuration: UIImage.SymbolConfiguration
  ) -> UIImage? {
    let name: String? = switch state {
    case .completed: "checkmark"
    case .current: nil
    case .upcoming: "circle"
    case .error: "exclamationmark"
    case .skipped: "forward.fill"
    case .disabled: "circle"
    }
    guard let name else { return nil }
    return UIImage(systemName: name, withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate)
  }

  static func numberLabel(for icon: FKFlowStepIcon?, state: FKFlowStepState, stepIndex: Int) -> String? {
    if case .number(let value) = icon {
      return "\(value)"
    }
    if icon == nil, state == .current || state == .upcoming {
      return "\(stepIndex + 1)"
    }
    return nil
  }
}
