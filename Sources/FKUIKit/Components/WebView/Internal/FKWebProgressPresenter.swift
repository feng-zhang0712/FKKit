import UIKit

@MainActor
final class FKWebProgressPresenter {
  private let progressBar: FKProgressBar
  private var hideCompletionTask: Task<Void, Never>?

  var presentation: FKWebProgressPresentation {
    didSet { applyPresentationMode() }
  }

  var progressConfiguration: FKWebProgressConfiguration {
    didSet {
      presentation = progressConfiguration.presentation
    }
  }

  init(configuration: FKWebProgressConfiguration) {
    self.progressConfiguration = configuration
    self.presentation = configuration.presentation

    var barConfiguration = FKProgressBarConfiguration()
    barConfiguration.layout.trackThickness = 2
    barConfiguration.label.placement = .none
    barConfiguration.appearance.showsBuffer = false
    progressBar = FKProgressBar(configuration: barConfiguration)
    progressBar.isHidden = true
    progressBar.alpha = 0
    applyPresentationMode()
  }

  var view: UIView { progressBar }

  func install(in container: UIView) {
    progressBar.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(progressBar)

    NSLayoutConstraint.activate([
      progressBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      progressBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      progressBar.heightAnchor.constraint(equalToConstant: 2),
    ])
  }

  func updateProgress(_ value: Double, isLoading: Bool) {
    hideCompletionTask?.cancel()

    switch presentation {
    case .none:
      hideImmediately()
      return
    case .indeterminateUntilFirstPaint where value <= 0 && isLoading:
      showIndeterminate()
      return
    case .linearBar, .linearBarTopSafeArea, .indeterminateUntilFirstPaint:
      showDeterminate(progress: value)
    }

    if value >= 1, !isLoading, progressConfiguration.hidesWhenComplete {
      scheduleHide(after: progressConfiguration.completeHideDelay)
    }
  }

  func hideForFailure() {
    hideCompletionTask?.cancel()
    hideImmediately()
  }

  func hideForCompletion() {
    hideCompletionTask?.cancel()
    if progressConfiguration.hidesWhenComplete {
      scheduleHide(after: progressConfiguration.completeHideDelay)
    } else {
      hideImmediately()
    }
  }

  private func applyPresentationMode() {
    switch presentation {
    case .none:
      hideImmediately()
    default:
      break
    }
  }

  private func showIndeterminate() {
    progressBar.isHidden = false
    progressBar.alpha = 1
    progressBar.isIndeterminate = true
  }

  private func showDeterminate(progress: Double) {
    progressBar.isHidden = false
    progressBar.alpha = 1
    progressBar.isIndeterminate = false
    progressBar.setProgress(CGFloat(min(max(progress, 0), 1)), animated: true)
  }

  private func scheduleHide(after delay: TimeInterval) {
    hideCompletionTask = Task { @MainActor in
      let nanoseconds = UInt64(max(delay, 0) * 1_000_000_000)
      try? await Task.sleep(nanoseconds: nanoseconds)
      guard !Task.isCancelled else { return }
      hideImmediately()
    }
  }

  private func hideImmediately() {
    progressBar.setProgress(0, animated: false)
    progressBar.isIndeterminate = false
    progressBar.alpha = 0
    progressBar.isHidden = true
  }
}
