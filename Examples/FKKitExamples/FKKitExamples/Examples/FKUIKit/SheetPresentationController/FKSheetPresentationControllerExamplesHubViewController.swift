import UIKit
import FKCoreKit
import FKUIKit

/// An index of `FKSheetPresentationController` examples, grouped by topic.
///
/// This is designed to be browsable and copy-friendly: each row navigates to a single focused example page.
final class FKSheetPresentationControllerExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "Mode",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.0.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.0.subtitle"),
          make: { BottomSheetBasicsExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.1.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.1.subtitle"),
          make: { BottomSheetScrollableContentExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.2.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.2.subtitle"),
          make: { ConfigurationPresetsExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.3.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.3.subtitle"),
          make: { TopSheetBasicsExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.4.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.4.subtitle"),
          make: { CenterModalBasicsExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.5.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.5.subtitle"),
          make: { EdgeLayoutExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Sheet",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.6.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.6.subtitle"),
          make: { SheetDetentsPointsExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.7.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.7.subtitle"),
          make: { SheetDetentsFractionExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.8.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.8.subtitle"),
          make: { SheetFitToContentExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.9.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.9.subtitle"),
          make: { SheetActionSheetStyleExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.10.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.10.subtitle"),
          make: { SheetGrabberExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.11.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.11.subtitle"),
          make: { SheetScrollTrackingExampleViewController() }
        ),
      ]
    ),
    Section(
      title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.2.title"),
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.12.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.12.subtitle"),
          make: { TapToDismissExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.13.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.13.subtitle"),
          make: { SwipeToDismissExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.14.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.14.subtitle"),
          make: { CrossDetentSwipeDismissExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.15.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.15.subtitle"),
          make: { BackgroundInteractionPolicyExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.16.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.16.subtitle"),
          make: { ZeroDimBackdropBehaviorExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.17.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.17.subtitle"),
          make: { InteractiveDismissProgressExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.18.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.18.subtitle"),
          make: { CallbackDeliveryExampleViewController() }
        ),
      ]
    ),
    Section(
      title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.3.title"),
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.19.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.19.subtitle"),
          make: { ContainerAppearanceTuningExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.20.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.20.subtitle"),
          make: { BottomSheetBlurExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.21.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.21.subtitle"),
          make: { TopSheetBlurExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.22.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.22.subtitle"),
          make: { CenterBlurExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.23.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.23.subtitle"),
          make: { AnchorBlurExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.24.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.24.subtitle"),
          make: { PresentingViewEffectExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Anchor",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.25.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.25.subtitle"),
          make: { AnchorTopSingleExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.26.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.26.subtitle"),
          make: { AnchorBottomSingleExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.27.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.27.subtitle"),
          make: { AnchorAutoDirectionExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.28.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.28.subtitle"),
          make: { AnchorContentReplacementExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.29.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.29.subtitle"),
          make: { AnchorNavigationBarExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.30.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.30.subtitle"),
          make: { AnchorScreenTopEdgeExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.31.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.31.subtitle"),
          make: { AnchorScreenBottomEdgeExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Safe Area",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.32.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.32.subtitle"),
          make: { SafeAreaContentRespectsSafeAreaExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.33.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.33.subtitle"),
          make: { SafeAreaContainerRespectsSafeAreaExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Backdrop",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.34.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.34.subtitle"),
          make: { DimBackdropExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.35.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.35.subtitle"),
          make: { MultiStageBackdropExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Animation",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.2.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.36.subtitle"),
          make: { AnimationPresetGalleryExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.37.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.37.subtitle"),
          make: { CustomAnimationTimingExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.38.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.38.subtitle"),
          make: { CustomAnimatorProviderExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.39.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.39.subtitle"),
          make: { ReduceMotionCompatibleAnimationExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Keyboard",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.40.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.40.subtitle"),
          make: { KeyboardAvoidanceExampleViewController() }
        ),
      ]
    ),
    Section(
      title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.18.title"),
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.41.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fksheetpresentationcontrollerexampleshubviewcont.41.subtitle"),
          make: { RotationResilienceExampleViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presentation"
    view.backgroundColor = .systemGroupedBackground
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var configuration = cell.defaultContentConfiguration()
    configuration.text = row.title
    configuration.secondaryText = row.subtitle
    configuration.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = configuration
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let row = sections[indexPath.section].rows[indexPath.row]
    navigationController?.pushViewController(row.make(), animated: true)
  }
}

