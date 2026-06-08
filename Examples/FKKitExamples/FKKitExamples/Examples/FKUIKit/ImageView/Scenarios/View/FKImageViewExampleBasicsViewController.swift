import FKUIKit
import UIKit

final class FKImageViewExampleBasicsViewController: UIViewController {
  private let imageView = FKImageView()
  private let stateLabel = FKImageViewExampleLayout.stateLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Remote URL"
    view.backgroundColor = .systemBackground

    imageView.apply {
      $0.loading.placeholder = .symbol(name: "photo", pointSize: 36, weight: .regular)
      $0.appearance.successTransition = .crossDissolve(duration: 0.25)
    }

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Loads a remote HTTPS image with symbol placeholder and cross-dissolve success transition."
    ))
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(stateLabel)
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Reload", action: UIAction { [weak self] _ in
      self?.imageView.reload()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Load another photo", action: UIAction { [weak self] _ in
      self?.imageView.load(url: FKImageViewExampleURLs.photo(id: Int.random(in: 20 ... 90)))
    }))

    FKImageViewExampleFactory.bindState(imageView, label: stateLabel)
    imageView.load(url: FKImageViewExampleURLs.photo(id: 42))
  }
}
