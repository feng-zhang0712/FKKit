import FKUIKit
import UIKit

final class FKEmptyStateRTLExampleViewController: UIViewController {
  private let container = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL"
    view.backgroundColor = .systemBackground
    fk_embedFill(container, in: view)
    render()
  }

  private func render() {
    var model = FKEmptyStateExampleFactory.makeBasicModel()
    model.content.title = "لا توجد بيانات بعد"
    model.content.description = "قم بإنشاء عنصر جديد لبدء الاستخدام."
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "create", title: "إنشاء عنصر", kind: .primary)
    )
    model.layout.forcedLayoutDirection = .rightToLeft
    model.appearance.typography.textAlignment = .right
    container.fk_applyEmptyState(model) { [weak self] _ in
      self?.fk_presentMessageAlert(title: "تم", message: "تم تنفيذ الإجراء الأساسي بنجاح.")
    }
  }
}
