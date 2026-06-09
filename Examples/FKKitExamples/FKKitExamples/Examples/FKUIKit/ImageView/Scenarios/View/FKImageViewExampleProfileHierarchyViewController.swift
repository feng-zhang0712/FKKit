import FKUIKit
import UIKit

/// Side-by-side comparison of ``FKImageViewProfile`` subtree depth after success, loading, and failure.
final class FKImageViewExampleProfileHierarchyViewController: UIViewController {
  private struct ProfileDemo {
    let title: String
    let imageView: FKImageView
    let summaryLabel = UILabel()
    let treeLabel = UILabel()
  }

  private let fullDemo = ProfileDemo(
    title: "Full profile",
    imageView: FKImageView(profile: .full)
  )
  private let listDemo = ProfileDemo(
    title: "List cell profile",
    imageView: FKImageView(profile: .listCell)
  )
  private let minimalDemo = ProfileDemo(
    title: "Minimal profile",
    imageView: FKImageView(profile: .minimal)
  )

  private let delayedLoader = FKImageExampleDelayedLoader()
  private let offlineStub = FKImageExampleStubLoader()
  private var nextPhotoID = 200

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Profile hierarchy"
    view.backgroundColor = .systemBackground

    delayedLoader.delay = 2
    offlineStub.mode = .offline
    fullDemo.imageView.imageLoader = delayedLoader
    fullDemo.imageView.apply {
      $0.loading.loadingPresentation = .init(progressMode: .activityIndicator, includesSkeleton: false)
    }

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Load the same photo into three profiles, then compare descendant counts. After success, list/minimal profiles keep a shallow subtree; full profile releases loading chrome. Use Xcode View Hierarchy Debugger to verify on device."
    ))

    for demo in [fullDemo, listDemo, minimalDemo] {
      stack.addArrangedSubview(FKImageViewExampleLayout.sectionHeader(demo.title))
      let host = FKImageViewExampleLayout.imageHost(height: 140)
      FKImageViewExampleLayout.embed(demo.imageView, in: host)
      stack.addArrangedSubview(host)

      demo.summaryLabel.font = .preferredFont(forTextStyle: .footnote)
      demo.summaryLabel.textColor = .secondaryLabel
      demo.summaryLabel.numberOfLines = 0
      stack.addArrangedSubview(demo.summaryLabel)

      demo.treeLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
      demo.treeLabel.textColor = .tertiaryLabel
      demo.treeLabel.numberOfLines = 0
      stack.addArrangedSubview(demo.treeLabel)
    }

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Load all (success)", action: UIAction { [weak self] _ in
      self?.loadAllSuccess()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Simulate loading (full only)", action: UIAction { [weak self] _ in
      self?.simulateFullLoading()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Simulate failure overlay (full only)", action: UIAction { [weak self] _ in
      self?.simulateFullFailure()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Refresh tree snapshot", action: UIAction { [weak self] _ in
      self?.refreshAllSnapshots()
    }))

    refreshAllSnapshots()
  }

  private func loadAllSuccess() {
    nextPhotoID += 1
    let url = FKImageViewExampleURLs.photo(id: nextPhotoID, size: 240)
    fullDemo.imageView.imageLoader = nil
    listDemo.imageView.imageLoader = nil
    minimalDemo.imageView.imageLoader = nil
    fullDemo.imageView.load(url: url)
    listDemo.imageView.load(url: url)
    minimalDemo.imageView.load(url: url)
    scheduleSnapshotRefresh()
  }

  private func simulateFullLoading() {
    nextPhotoID += 1
    fullDemo.imageView.imageLoader = delayedLoader
    fullDemo.imageView.load(url: FKImageViewExampleURLs.photo(id: nextPhotoID, size: 240))
    refreshAllSnapshots()
    scheduleSnapshotRefresh()
  }

  private func simulateFullFailure() {
    fullDemo.imageView.imageLoader = offlineStub
    fullDemo.imageView.load(url: FKImageViewExampleURLs.photo(id: 404, size: 240))
    refreshAllSnapshots()
    scheduleSnapshotRefresh()
  }

  private func scheduleSnapshotRefresh() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
      self?.refreshAllSnapshots()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
      self?.refreshAllSnapshots()
    }
  }

  private func refreshAllSnapshots() {
    refreshSnapshot(for: fullDemo)
    refreshSnapshot(for: listDemo)
    refreshSnapshot(for: minimalDemo)
  }

  private func refreshSnapshot(for demo: ProfileDemo) {
    let total = FKImageViewExampleHierarchy.descendantCount(of: demo.imageView)
    let visible = FKImageViewExampleHierarchy.visibleDescendantCount(of: demo.imageView)
    let state = FKImageViewExampleFormatting.describe(demo.imageView.state)
    demo.summaryLabel.text = "State: \(state) · descendants=\(total) · visible=\(visible)"
    demo.treeLabel.text = FKImageViewExampleHierarchy.treeDescription(for: demo.imageView)
  }
}
