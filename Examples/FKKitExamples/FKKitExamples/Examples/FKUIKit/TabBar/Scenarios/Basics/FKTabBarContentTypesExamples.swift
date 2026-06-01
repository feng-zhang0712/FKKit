import UIKit
import FKUIKit

final class FKTabBarContentTypesExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(layout: .init(intrinsicWidthMeasurement: .adjustsOnSelection))
  private lazy var tabView = FKTabBar(
    items: FKTabBarExampleSupport.makeMixedContentItems(),
    selectedIndex: 0,
    configuration: configuration
  )
  private let measurementControl = UISegmentedControl(items: ["normalStateOnly", "adjustsOnSelection"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Content types"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Text / symbol / image / custom view in one unified item model"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Image uses a short normal title and a long selected title. Toggle intrinsic width measurement below, then select Image to compare stable vs selection-aware tab widths."
      )
    )

    measurementControl.selectedSegmentIndex = 1
    measurementControl.addAction(UIAction { [weak self] _ in
      self?.applyMeasurementMode()
    }, for: .valueChanged)
    stack.addArrangedSubview(measurementControl)

    tabView.customization = FKTabBarExampleContentCustomization()

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: 56)
  }

  private func applyMeasurementMode() {
    configuration.layout.intrinsicWidthMeasurement = measurementControl.selectedSegmentIndex == 0
      ? .normalStateOnly
      : .adjustsOnSelection
    tabView.applyConfiguration(configuration, animated: false)
  }
}
