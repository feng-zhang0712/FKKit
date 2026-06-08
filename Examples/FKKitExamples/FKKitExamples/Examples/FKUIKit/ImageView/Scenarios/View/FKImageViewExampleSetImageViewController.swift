import FKUIKit
import UIKit

final class FKImageViewExampleSetImageViewController: UIViewController {
  private let imageView = FKImageView()
  private let stateLabel = FKImageViewExampleLayout.stateLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "setImage"
    view.backgroundColor = .systemBackground

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "setImage(_:animated:) binds a local bitmap without URL or loader involvement."
    ))
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(stateLabel)
    FKImageViewExampleFactory.bindState(imageView, label: stateLabel)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Set local image", action: UIAction { [weak self] _ in
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
      let image = renderer.image { ctx in
        UIColor.systemOrange.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
      }
      self?.imageView.setImage(image, animated: true)
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Clear (setImage nil)", action: UIAction { [weak self] _ in
      self?.imageView.setImage(nil)
    }))
  }
}
