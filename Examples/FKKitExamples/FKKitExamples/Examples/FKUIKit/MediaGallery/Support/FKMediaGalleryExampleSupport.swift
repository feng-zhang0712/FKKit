import FKUIKit
import UIKit

enum FKMediaGalleryExampleUI {
  static func section(title: String, description: String, body: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 8

    let titleLabel = UILabel()
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0
    titleLabel.text = title

    let descriptionLabel = UILabel()
    descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
    descriptionLabel.textColor = .secondaryLabel
    descriptionLabel.numberOfLines = 0
    descriptionLabel.text = description

    wrap.addArrangedSubview(titleLabel)
    wrap.addArrangedSubview(descriptionLabel)
    wrap.addArrangedSubview(body)
    return wrap
  }

  static func button(_ title: String, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    var configuration = UIButton.Configuration.gray()
    configuration.cornerStyle = .medium
    configuration.title = title
    configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    configuration.titleLineBreakMode = .byWordWrapping
    configuration.titleAlignment = .center
    configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = .preferredFont(forTextStyle: .callout)
      return outgoing
    }
    button.configuration = configuration
    button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
  }

  static func caption(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }
}

@MainActor
final class FKMediaGalleryExampleLog {
  static let shared = FKMediaGalleryExampleLog()

  private(set) var lines: [String] = []
  private var observers: [UUID: () -> Void] = [:]

  private init() {}

  var displayText: String {
    lines.isEmpty ? "Gallery delegate events will appear here." : lines.joined(separator: "\n")
  }

  func append(_ line: String) {
    let stamp = Self.timeFormatter.string(from: Date())
    lines.insert("[\(stamp)] \(line)", at: 0)
    if lines.count > 80 {
      lines.removeLast(lines.count - 80)
    }
    observers.values.forEach { $0() }
  }

  func clear() {
    lines.removeAll()
    observers.values.forEach { $0() }
  }

  @discardableResult
  func addObserver(_ handler: @escaping () -> Void) -> UUID {
    let id = UUID()
    observers[id] = handler
    return id
  }

  func removeObserver(_ id: UUID) {
    observers.removeValue(forKey: id)
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}

@MainActor
final class FKMediaGalleryExampleDelegateLogger: NSObject, FKMediaGalleryDelegate {
  private let prefix: String

  init(prefix: String = "gallery") {
    self.prefix = prefix
  }

  func mediaGallery(_ gallery: FKMediaGallery, willPresentWith itemCount: Int) {
    FKMediaGalleryExampleLog.shared.append("\(prefix) willPresent · count=\(itemCount)")
  }

  func mediaGallery(_ gallery: FKMediaGallery, didChangeCurrentIndex newIndex: Int, previousIndex: Int) {
    FKMediaGalleryExampleLog.shared.append("\(prefix) page \(previousIndex) → \(newIndex)")
  }

  func mediaGallery(_ gallery: FKMediaGallery, didDismissAt finalIndex: Int?) {
    FKMediaGalleryExampleLog.shared.append("\(prefix) didDismiss · finalIndex=\(finalIndex.map(String.init) ?? "nil")")
  }

  func mediaGallery(
    _ gallery: FKMediaGallery,
    didFailToLoad item: FKMediaGalleryItem,
    at index: Int,
    error: FKMediaGalleryError
  ) {
    FKMediaGalleryExampleLog.shared.append("\(prefix) load failed @\(index): \(error.localizedDescription)")
  }

  func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestShare item: FKMediaGalleryItem,
    at index: Int,
    sourceView: UIView
  ) -> Bool {
    FKMediaGalleryExampleLog.shared.append("\(prefix) share requested @\(index) · using default")
    return false
  }

  func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestSaveToPhotos item: FKMediaGalleryItem,
    at index: Int
  ) -> Bool {
    FKMediaGalleryExampleLog.shared.append("\(prefix) save requested @\(index) · using default")
    return false
  }

  func mediaGallery(
    _ gallery: FKMediaGallery,
    requestFullScreenVideoPlayerFor item: FKMediaGalleryItem,
    at index: Int,
    player: FKVideoPlayer
  ) -> Bool {
    FKMediaGalleryExampleLog.shared.append("\(prefix) full-screen video handoff @\(index)")
    return false
  }
}

@MainActor
class FKMediaGalleryExampleBaseViewController: UIViewController {
  let scrollView = UIScrollView()
  let contentStack = UIStackView()
  let logTextView = UITextView()
  let gallery = FKMediaGallery()
  let delegateLogger = FKMediaGalleryExampleDelegateLogger()

  private var logObserverID: UUID?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    gallery.delegate = delegateLogger

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.spacing = 16
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)
    view.addSubview(scrollView)

    logTextView.isEditable = false
    logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logTextView.backgroundColor = .secondarySystemGroupedBackground
    logTextView.layer.cornerRadius = 8
    logTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    logTextView.translatesAutoresizingMaskIntoConstraints = false
    logTextView.heightAnchor.constraint(equalToConstant: 140).isActive = true

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
    ])

    contentStack.addArrangedSubview(logTextView)
    contentStack.addArrangedSubview(FKMediaGalleryExampleUI.button("Clear log") {
      FKMediaGalleryExampleLog.shared.clear()
    })

    logObserverID = FKMediaGalleryExampleLog.shared.addObserver { [weak self] in
      self?.refreshLog()
    }
    refreshLog()
  }

  deinit {
    if let logObserverID {
      Task { @MainActor in
        FKMediaGalleryExampleLog.shared.removeObserver(logObserverID)
      }
    }
  }

  func refreshLog() {
    logTextView.text = FKMediaGalleryExampleLog.shared.displayText
  }

  func presentGallery(
    items: [FKMediaGalleryItem],
    startIndex: Int = 0,
    transitionSource: FKMediaGalleryTransitionSource? = nil,
    configuration: FKMediaGalleryConfiguration = FKMediaGalleryPresets.socialFeed()
  ) {
    do {
      try gallery.present(
        from: self,
        items: items,
        startIndex: startIndex,
        transitionSource: transitionSource,
        configuration: configuration
      )
    } catch {
      FKMediaGalleryExampleLog.shared.append("present failed: \(error.localizedDescription)")
    }
  }
}
