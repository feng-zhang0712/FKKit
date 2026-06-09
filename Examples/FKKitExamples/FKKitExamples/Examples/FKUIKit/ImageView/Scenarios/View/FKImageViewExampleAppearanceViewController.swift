import FKUIKit
import UIKit

final class FKImageViewExampleAppearanceViewController: UIViewController {
  private let imageView = FKImageView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Appearance"
    view.backgroundColor = .systemBackground

    imageView.apply {
      $0.appearance.cornerStyle = .fixed(16)
      $0.appearance.borderStyle = .custom(color: .separator, width: 2)
      $0.appearance.shadowStyle = .custom(
        color: .black,
        opacity: 0.18,
        radius: 10,
        offset: CGSize(width: 0, height: 4)
      )
      $0.appearance.contentMode = .scaleAspectFill
      $0.appearance.backgroundColor = .systemBackground
    }

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "CornerStyle, border, shadow, and contentMode from FKImageViewAppearanceConfiguration."
    ))
    let host = FKImageViewExampleLayout.imageHost(height: 200)
    host.backgroundColor = .clear
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)

    let styles = ["Fixed", "Capsule", "Per-corner"]
    let picker = UISegmentedControl(items: styles)
    picker.selectedSegmentIndex = 0
    picker.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      switch picker.selectedSegmentIndex {
      case 1: imageView.fk_setCornerStyle(.capsule)
      case 2: imageView.fk_setCornerStyle(.perCorner([.topLeft, .bottomRight], radius: 24))
      default: imageView.fk_setCornerStyle(.fixed(16))
      }
    }, for: .valueChanged)
    stack.addArrangedSubview(picker)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Toggle aspectFit", action: UIAction { [weak self] _ in
      guard let self else { return }
      imageView.contentMode = imageView.contentMode == .scaleAspectFill ? .scaleAspectFit : .scaleAspectFill
    }))

    imageView.load(url: FKImageViewExampleURLs.photo(id: 30))
  }
}
