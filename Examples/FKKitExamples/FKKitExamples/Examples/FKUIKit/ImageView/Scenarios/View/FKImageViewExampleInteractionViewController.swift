import FKUIKit
import UIKit

final class FKImageViewExampleInteractionViewController: UIViewController {
  private let imageView = FKImageView()
  private let feedbackLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Interaction"
    view.backgroundColor = .systemBackground

    imageView.apply {
      $0.interaction.highlightOnPress = true
      $0.accessibility.isDecorative = false
      $0.accessibility.imageDescription = "Sample landscape photo"
      $0.accessibility.announcesLayoutChangeOnSuccess = true
    }
    imageView.onTap = { [weak self] in
      self?.feedbackLabel.text = "onTap fired at \(Date().formatted(date: .omitted, time: .standard))"
    }

    feedbackLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    feedbackLabel.textColor = .secondaryLabel
    feedbackLabel.numberOfLines = 0
    feedbackLabel.text = "Tap the image after it loads."

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "onTap callback, press highlight, and accessibility configuration."
    ))
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(feedbackLabel)

    imageView.load(url: FKImageViewExampleURLs.photo(id: 18))
  }
}
