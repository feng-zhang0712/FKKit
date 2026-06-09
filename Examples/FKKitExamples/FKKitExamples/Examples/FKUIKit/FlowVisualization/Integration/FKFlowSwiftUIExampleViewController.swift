import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKFlowSwiftUIDemoRoot: View {
  @State private var stepIndex = 1
  @State private var stepConfiguration: FKStepIndicatorConfiguration = {
    var config = FKStepIndicatorPresets.onboarding()
    return config
  }()
  @State private var timelineConfiguration = FKTimelinePresets.logistics()

  private let checkoutItems = FKFlowVisualizationExampleSupport.checkoutItems()
  private let logisticsItems = FKFlowVisualizationExampleSupport.logisticsItems()

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKStepIndicatorRepresentable(
            items: checkoutItems,
            currentStepIndex: stepIndex,
            configuration: stepConfiguration
          ) { newIndex in
            stepIndex = newIndex
          }
          .frame(minHeight: 88)
        } header: {
          Text("FKStepIndicatorRepresentable")
        } footer: {
          Text("Binding-friendly wrapper; selection updates `stepIndex` when interaction is enabled.")
        }

        Section("Step index") {
          Stepper("Current step: \(stepIndex + 1)", value: $stepIndex, in: 0 ... max(0, checkoutItems.count - 1))
        }

        Section {
          FKTimelineRepresentable(
            items: logisticsItems,
            configuration: timelineConfiguration
          )
          .frame(minHeight: 260)
        } header: {
          Text("FKTimelineRepresentable")
        }
      }
      .navigationTitle("SwiftUI")
    }
    .navigationViewStyle(.stack)
  }
}
#endif

/// Hosts SwiftUI representables for step indicator and timeline.
final class FKFlowSwiftUIExampleViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

#if canImport(SwiftUI)
    title = "SwiftUI bridge"
    let host = UIHostingController(rootView: FKFlowSwiftUIDemoRoot())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
#else
    title = "SwiftUI"
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.text = "SwiftUI is not available in this build."
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
      label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
    ])
#endif
  }
}
