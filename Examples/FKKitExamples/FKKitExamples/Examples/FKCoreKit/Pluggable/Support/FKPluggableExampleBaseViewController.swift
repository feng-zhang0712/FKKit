import UIKit

/// Shared scroll + action buttons + monospace log output for FKPluggable demos.
@MainActor
class FKPluggableExampleBaseViewController: UIViewController {

  private let scrollView = UIScrollView()
  let stackView = UIStackView()
  private let outputView = UITextView()

  private var outputLines: [String] = []

  private let maxOutputLines = 80
  private let maxOutputCharacters = 8_000

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    buildLayout()
  }

  func appendOutput(_ line: String) {
    outputLines.append(line)
    if outputLines.count > maxOutputLines {
      outputLines.removeFirst(outputLines.count - maxOutputLines)
    }

    var text = outputLines.joined(separator: "\n")
    if text.count > maxOutputCharacters {
      text = String(text.suffix(maxOutputCharacters))
      outputLines = text.components(separatedBy: "\n")
    }

    // Assign once; log view height is constraint-bounded (not stack-intrinsic-sized).
    outputView.text = text
  }

  func clearOutput() {
    outputLines.removeAll()
    outputView.text = ""
  }

  func addActionButton(_ title: String, action: @escaping () -> Void) {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    config.buttonSize = .small
    config.titleAlignment = .leading
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    let button = UIButton(configuration: config)
    button.isExclusiveTouch = true
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    stackView.addArrangedSubview(button)
  }

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8

    outputView.translatesAutoresizingMaskIntoConstraints = false
    outputView.isEditable = false
    outputView.isScrollEnabled = true
    outputView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    outputView.backgroundColor = .secondarySystemBackground
    outputView.layer.cornerRadius = 8
    outputView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    // Prevent UITextView from expanding the layout system to fit all text (causes runaway CPU/memory).
    outputView.setContentHuggingPriority(.defaultLow, for: .vertical)
    outputView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

    scrollView.addSubview(stackView)
    view.addSubview(scrollView)
    view.addSubview(outputView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.48),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -4),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      outputView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      outputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      outputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      outputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}
