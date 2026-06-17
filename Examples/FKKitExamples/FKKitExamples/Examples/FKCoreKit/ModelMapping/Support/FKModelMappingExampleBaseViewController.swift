import UIKit

/// Shared scroll layout, action buttons, and monospace log output for FKModelMapping demos.
@MainActor
class FKModelMappingExampleBaseViewController: UIViewController {
  private let scrollView = UIScrollView()
  let stackView = UIStackView()
  private let outputView = UITextView()

  private var outputLines: [String] = []
  private let maxOutputLines = 100
  private let maxOutputCharacters = 12_000

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .never
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
    outputView.text = text
  }

  func clearOutput() {
    outputLines.removeAll()
    outputView.text = ""
  }

  @discardableResult
  func addActionButton(_ title: String, action: @escaping () -> Void) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    config.buttonSize = .small
    config.titleAlignment = .leading
    config.baseBackgroundColor = .secondarySystemFill
    config.baseForegroundColor = .label
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    let button = UIButton(configuration: config)
    button.isExclusiveTouch = true
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    stackView.addArrangedSubview(button)
    return button
  }

  func addInfoLabel(_ text: String) {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    stackView.addArrangedSubview(label)
  }

  func runMapping(_ title: String, operation: () throws -> String) {
    appendOutput("--- \(title) ---")
    do {
      appendOutput(try operation())
    } catch {
      appendOutput(FKModelMappingExampleSupport.describe(error: error))
    }
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
    outputView.setContentHuggingPriority(.defaultLow, for: .vertical)

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    stackView.addArrangedSubview(outputView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),

      outputView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),
    ])
  }
}
