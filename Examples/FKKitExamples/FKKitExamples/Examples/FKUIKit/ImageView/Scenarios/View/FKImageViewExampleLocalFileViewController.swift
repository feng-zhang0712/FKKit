import FKUIKit
import UIKit

final class FKImageViewExampleLocalFileViewController: UIViewController {
  private let imageView = FKImageView()
  private let stateLabel = FKImageViewExampleLayout.stateLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Local file"
    view.backgroundColor = .systemBackground

    let fileURL = FKImageViewExampleFactory.makeLocalFileURL()

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Loads a file:// URL written to the temporary directory. FKImageLoader reads and decodes on a background queue."
    ))
    stack.addArrangedSubview(FKImageViewExampleLayout.caption("Path: \(fileURL.path)"))
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(stateLabel)
    FKImageViewExampleFactory.bindState(imageView, label: stateLabel)

    imageView.load(url: fileURL)
  }
}
