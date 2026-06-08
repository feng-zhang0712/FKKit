import FKUIKit
import UIKit

final class FKImageViewExamplePlaceholdersViewController: UIViewController {
  private let imageView = FKImageView()
  private let stateLabel = FKImageViewExampleLayout.stateLabel()
  private let modePicker = UISegmentedControl(items: ["Symbol", "Color", "Initials", "Custom view"])
  private var nextPhotoID = 11

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Placeholders"
    view.backgroundColor = .systemBackground

    imageView.apply {
      $0.loading.loadsAutomatically = false
    }

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "1. Pick a segment to preview that placeholder style (no network yet).\n2. Tap Apply & load to fetch a remote image and see the placeholder during loading."
    ))
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(stateLabel)
    FKImageViewExampleFactory.bindState(imageView, label: stateLabel)

    modePicker.selectedSegmentIndex = 0
    modePicker.addAction(UIAction { [weak self] _ in
      self?.previewPlaceholder()
    }, for: .valueChanged)
    stack.addArrangedSubview(modePicker)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Apply & load", action: UIAction { [weak self] _ in
      self?.loadRemoteImage()
    }))

    previewPlaceholder()
  }

  /// Applies placeholder configuration and shows it without starting a fetch.
  private func previewPlaceholder() {
    applyPlaceholder(mode: modePicker.selectedSegmentIndex)
    imageView.load(url: FKImageViewExampleURLs.photo(id: nextPhotoID, size: 320))
  }

  /// Starts a network load so the selected placeholder appears while fetching.
  private func loadRemoteImage() {
    applyPlaceholder(mode: modePicker.selectedSegmentIndex)
    nextPhotoID += 1
    imageView.apply { $0.loading.loadsAutomatically = true }
    imageView.load(url: FKImageViewExampleURLs.photo(id: nextPhotoID, size: 320))
    imageView.apply { $0.loading.loadsAutomatically = false }
  }

  private func applyPlaceholder(mode: Int) {
    imageView.configuration.loading.customPlaceholderProvider = nil
    switch mode {
    case 0:
      imageView.apply { $0.loading.placeholder = .symbol(name: "photo", pointSize: 32, weight: .regular) }
    case 1:
      imageView.apply { $0.loading.placeholder = .color(.secondarySystemFill) }
    case 2:
      imageView.apply {
        $0.loading.placeholder = .initials(
          text: "FK",
          font: .boldSystemFont(ofSize: 28),
          textColor: .white,
          backgroundColor: .systemIndigo
        )
      }
    case 3:
      imageView.apply {
        $0.loading.placeholder = .none
        $0.loading.customPlaceholderProvider = {
          let label = UILabel()
          label.text = "Custom slot"
          label.textAlignment = .center
          label.font = .preferredFont(forTextStyle: .subheadline)
          label.textColor = .secondaryLabel
          label.backgroundColor = .tertiarySystemFill
          return label
        }
      }
    default:
      break
    }
  }
}
