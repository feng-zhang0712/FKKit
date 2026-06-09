import FKUIKit
import UIKit

final class FKImageViewExampleManualLoadViewController: UIViewController {
  private let imageView = FKImageView()
  private let stateLabel = FKImageViewExampleLayout.stateLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Manual load"
    view.backgroundColor = .systemBackground

    imageView.apply {
      $0.loading.loadsAutomatically = false
      $0.loading.placeholder = .color(.secondarySystemFill)
    }

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Assign url without auto-start; call startLoading(), cancelLoad(), or reload() explicitly."
    ))
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(stateLabel)
    FKImageViewExampleFactory.bindState(imageView, label: stateLabel)

    imageView.load(url: FKImageViewExampleURLs.photo(id: 64), placeholder: .symbol(name: "hourglass", pointSize: 28, weight: .regular))

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "startLoading()", action: UIAction { [weak self] _ in
      self?.imageView.startLoading()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "cancelLoad()", action: UIAction { [weak self] _ in
      self?.imageView.cancelLoad()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "reload() (skip memory)", action: UIAction { [weak self] _ in
      self?.imageView.reload()
    }))
  }
}
