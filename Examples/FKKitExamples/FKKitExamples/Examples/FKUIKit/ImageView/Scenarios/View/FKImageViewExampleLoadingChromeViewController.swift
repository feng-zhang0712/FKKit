import FKUIKit
import UIKit

final class FKImageViewExampleLoadingChromeViewController: UIViewController {
  private let imageView = FKImageView()
  private let stateLabel = FKImageViewExampleLayout.stateLabel()
  private let modePicker = UISegmentedControl(items: ["None", "Spinner", "Progress bar", "Skeleton"])
  private let delayedLoader = FKImageExampleDelayedLoader()
  private var nextPhotoID = 55

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Loading chrome"
    view.backgroundColor = .systemBackground

    delayedLoader.delay = 2.5
    imageView.imageLoader = delayedLoader
    imageView.apply {
      $0.loading.placeholder = .color(.secondarySystemFill)
      $0.loading.loadingPresentation = .init(progressMode: .activityIndicator, includesSkeleton: false)
    }

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Pick a chrome style, then tap Load. A 2.5s delayed loader keeps loading visible so progress bar and skeleton are easy to compare with the spinner."
    ))
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(stateLabel)
    FKImageViewExampleFactory.bindState(imageView, label: stateLabel)

    modePicker.selectedSegmentIndex = 1
    modePicker.addAction(UIAction { [weak self] _ in
      self?.triggerLoad()
    }, for: .valueChanged)
    stack.addArrangedSubview(modePicker)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Load (delayed fetch)", action: UIAction { [weak self] _ in
      self?.triggerLoad()
    }))

    applyMode(1)
  }

  private func triggerLoad() {
    applyMode(modePicker.selectedSegmentIndex)
    nextPhotoID += 1
    imageView.load(url: FKImageViewExampleURLs.photo(id: nextPhotoID, size: 480))
  }

  private func applyMode(_ index: Int) {
    switch index {
    case 0:
      imageView.apply { $0.loading.loadingPresentation = .init(progressMode: .none, includesSkeleton: false) }
    case 1:
      imageView.apply { $0.loading.loadingPresentation = .init(progressMode: .activityIndicator, includesSkeleton: false) }
    case 2:
      var bar = FKProgressBarConfiguration()
      bar.layout.trackThickness = 6
      bar.appearance.trackColor = .tertiarySystemFill
      bar.appearance.progressColor = .systemBlue
      bar.motion.indeterminateStyle = .marquee
      imageView.apply {
        $0.loading.loadingPresentation = .init(progressMode: .linearProgress(bar), includesSkeleton: false)
      }
    default:
      var skeleton = FKSkeletonConfiguration()
      skeleton.baseColor = .tertiarySystemFill
      skeleton.highlightColor = .secondarySystemFill
      imageView.apply {
        $0.loading.loadingPresentation = .init(
          progressMode: .none,
          includesSkeleton: true,
          skeletonConfiguration: skeleton
        )
      }
    }
  }
}
