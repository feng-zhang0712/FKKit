import FKUIKit
import UIKit

final class FKImageViewExampleCustomLoaderViewController: UIViewController {
  private let imageView = FKImageView()
  private let stubLoader = FKImageExampleStubLoader()
  private let defaultsLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom loader"
    view.backgroundColor = .systemBackground

    imageView.imageLoader = stubLoader

    defaultsLabel.font = .preferredFont(forTextStyle: .footnote)
    defaultsLabel.textColor = .secondaryLabel
    defaultsLabel.numberOfLines = 0
    defaultsLabel.text = "FKImageViewDefaults.sharedImageLoader is unchanged; this view uses imageLoader override."

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Inject any FKImageLoading implementation per view. Stub delegates to shared loader in .shared mode."
    ))
    stack.addArrangedSubview(defaultsLabel)
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Load via stub (.shared)", action: UIAction { [weak self] _ in
      self?.stubLoader.mode = .shared
      self?.imageView.load(url: FKImageViewExampleURLs.photo(id: 12))
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Simulate offline stub", action: UIAction { [weak self] _ in
      self?.stubLoader.mode = .offline
      self?.imageView.load(url: FKImageViewExampleURLs.photo(id: 12))
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Apply global corner default", action: UIAction { _ in
      FKImageViewDefaults.defaultConfiguration.appearance.cornerStyle = .capsule
      FKImageViewDefaults.defaultConfiguration.loading.placeholder = .color(.tertiarySystemFill)
    }))
  }
}
