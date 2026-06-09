import UIKit

/// Content view controller hosted inside ``FKSheetPresentationController`` center alert layout.
@MainActor
public final class FKAlertViewController: UIViewController {
  /// Declarative content shown by the alert.
  public private(set) var content: FKAlertContent
  /// Active configuration.
  public private(set) var configuration: FKAlertConfiguration

  var onActionSelected: ((FKAlertResolvedAction) -> Void)?
  /// Called when UIKit dismisses the controller without an explicit action selection.
  var onUIKitDismiss: (() -> Void)?

  private let contentView = FKAlertContentView()
  private let resolvedActions: [FKAlertResolvedAction]
  private var isLoading = false

  /// Creates an alert content controller.
  init(
    content: FKAlertContent,
    configuration: FKAlertConfiguration,
    resolvedActions: [FKAlertResolvedAction]
  ) {
    self.content = content
    self.configuration = configuration
    self.resolvedActions = resolvedActions
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = configuration.appearance.backgroundColor
    if let identifier = content.accessibilityIdentifier {
      view.accessibilityIdentifier = identifier
    }

    contentView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(contentView)
    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: view.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    contentView.onActionSelected = { [weak self] action in
      self?.onActionSelected?(action)
    }
    contentView.onPreferredContentSizeInvalidated = { [weak self] in
      self?.updatePreferredContentSize()
    }

    contentView.apply(
      content: content,
      configuration: configuration,
      resolvedActions: resolvedActions,
      isLoading: isLoading
    )
    updatePreferredContentSize()
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if configuration.accessibility.announcesOnPresent {
      let announcement = [content.title, resolvedAccessibilityMessageBody(from: content)]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: ". ")
      if !announcement.isEmpty {
        UIAccessibility.post(notification: .announcement, argument: announcement)
      }
    }

    guard configuration.interaction.autoFocusTextField, content.textInput != nil else {
      contentView.focusPreferredElement()
      return
    }
    Task { @MainActor [weak self] in
      try? await Task.sleep(nanoseconds: 100_000_000)
      self?.contentView.focusPreferredElement()
    }
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    guard isBeingDismissed else { return }
    onUIKitDismiss?()
  }

  /// Updates loading state on primary/destructive buttons.
  public func setLoading(_ isLoading: Bool) {
    self.isLoading = isLoading
    contentView.setLoading(isLoading)
  }

  /// Validates optional text input using alert rules.
  public func validateTextInput() -> Bool {
    contentView.validateTextInput()
  }

  /// Returns trimmed text field content when present.
  public func currentTextValue() -> String? {
    contentView.currentTextValue()?.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard view.bounds.width > 1 else { return }
    updatePreferredContentSize()
  }

  private func updatePreferredContentSize() {
    let targetWidth: CGFloat = view.bounds.width > 1 ? view.bounds.width : 320
    let height = contentView.preferredContentHeight(forWidth: targetWidth)
    let nextSize = CGSize(width: targetWidth, height: max(44, height))
    guard preferredContentSize != nextSize else { return }
    preferredContentSize = nextSize
  }

  private func resolvedAccessibilityMessageBody(from content: FKAlertContent) -> String? {
    if let message = content.message, !message.isEmpty { return message }
    guard let data = content.attributedMessage,
          let attributed = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data),
          !attributed.string.isEmpty else { return nil }
    return attributed.string
  }
}
