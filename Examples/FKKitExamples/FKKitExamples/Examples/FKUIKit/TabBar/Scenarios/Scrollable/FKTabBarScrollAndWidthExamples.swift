import UIKit
import FKUIKit

final class FKTabBarScrollAndWidthStrategyExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(layout: .init(isScrollable: true, widthMode: .intrinsic))
  private let widthCustomization = FKTabBarExampleWidthCustomization()
  private lazy var tabView = FKTabBar(items: FKTabBarExampleSupport.makeLongTitleItems(), selectedIndex: 0, configuration: configuration)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scroll + Width"
    view.backgroundColor = .systemBackground
    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Auto-scroll target position and width policy comparison"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Compare minimal/center/leading/trailing scroll target and intrinsic/fixed/fill/constrained/custom widths."))

    let scroll = UISegmentedControl(items: ["Minimal", "Center", "Leading", "Trailing"])
    scroll.selectedSegmentIndex = 1
    scroll.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.configuration.layout.selectionScrollPosition = [.minimalVisible, .center, .leading, .trailing][scroll.selectedSegmentIndex]
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(scroll)

    let width = UISegmentedControl(items: ["Intrinsic", "Fixed", "Fill", "Range", "Custom"])
    width.selectedSegmentIndex = 0
    width.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.tabView.customization = nil
      switch width.selectedSegmentIndex {
      case 1: self.configuration.layout.widthMode = .fixed(120)
      case 2:
        self.configuration.layout.isScrollable = false
        self.configuration.layout.widthMode = .fillEqually
      case 3:
        self.configuration.layout.isScrollable = true
        self.configuration.layout.widthMode = .constrained(min: 80, max: 160)
      case 4:
        self.configuration.layout.isScrollable = true
        self.configuration.layout.widthMode = .intrinsic
        self.tabView.customization = self.widthCustomization
      default:
        self.configuration.layout.isScrollable = true
        self.configuration.layout.widthMode = .intrinsic
      }
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(width)

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: 56)
  }
}
