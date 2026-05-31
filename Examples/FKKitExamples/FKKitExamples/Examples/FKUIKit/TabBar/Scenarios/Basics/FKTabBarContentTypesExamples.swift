import UIKit
import FKUIKit

final class FKTabBarContentTypesExampleViewController: UIViewController {
  private let tabView = FKTabBar(items: FKTabBarExampleSupport.makeMixedContentItems(), selectedIndex: 0)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Content types"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Text / symbol / image / custom view in one unified item model"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Tab Item rendered by FKButton. Validates text/symbol/image/custom rendering via FKTabBarCustomization.customContentView(for:)."))

    tabView.customization = FKTabBarExampleContentCustomization()

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: 56)
  }
}
