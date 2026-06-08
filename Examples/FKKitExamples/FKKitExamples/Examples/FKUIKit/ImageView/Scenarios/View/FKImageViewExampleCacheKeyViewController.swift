import FKUIKit
import UIKit

final class FKImageViewExampleCacheKeyViewController: UIViewController {
  private let imageViewA = FKImageView()
  private let imageViewB = FKImageView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Cache key"
    view.backgroundColor = .systemBackground

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Same URL with different cacheKey values maintains separate cache buckets (e.g. avatar sizes)."
    ))

    stack.addArrangedSubview(FKImageViewExampleLayout.sectionHeader("Bucket A · avatar-small"))
    let hostA = FKImageViewExampleLayout.imageHost(height: 120)
    FKImageViewExampleLayout.embed(imageViewA, in: hostA)
    stack.addArrangedSubview(hostA)

    stack.addArrangedSubview(FKImageViewExampleLayout.sectionHeader("Bucket B · avatar-large"))
    let hostB = FKImageViewExampleLayout.imageHost(height: 160)
    FKImageViewExampleLayout.embed(imageViewB, in: hostB)
    stack.addArrangedSubview(hostB)

    let url = FKImageViewExampleURLs.photo(id: 33, size: 400)
    imageViewA.cacheKey = "demo-avatar-small"
    imageViewB.cacheKey = "demo-avatar-large"
    imageViewA.load(url: url)
    imageViewB.load(url: url)
  }
}
