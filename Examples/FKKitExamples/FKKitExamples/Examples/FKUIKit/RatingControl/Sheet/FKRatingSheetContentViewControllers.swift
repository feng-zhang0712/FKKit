import FKUIKit
import UIKit

// MARK: - Sheet content base

/// Base layout for centered sheet content that reports a fitted `preferredContentSize`.
@MainActor
class FKRatingSheetContentViewController: UIViewController {
  let contentStack = UIStackView()
  var preferredWidth: CGFloat
  /// When `false`, the host sheet supplies a fixed size (for example App Store alert).
  var updatesPreferredContentSizeAutomatically = true

  init(preferredWidth: CGFloat = 320) {
    self.preferredWidth = preferredWidth
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    view.clipsToBounds = true

    contentStack.translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.spacing = 20
    contentStack.alignment = .fill
    contentStack.isLayoutMarginsRelativeArrangement = true
    contentStack.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
    view.addSubview(contentStack)

    NSLayoutConstraint.activate([
      contentStack.topAnchor.constraint(equalTo: view.topAnchor),
      contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      contentStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard updatesPreferredContentSizeAutomatically else { return }
    FKRatingSheetExampleSupport.updatePreferredContentSize(for: self, width: preferredWidth)
  }
}

// MARK: - Quick rate (center card)

/// Compact centered sheet with a star row and primary actions.
final class FKRatingQuickRateSheetContentViewController: FKRatingSheetContentViewController {

  private let rating = FKRatingControl.interactiveStars(value: 0, step: .whole)
  private var submitButton: UIButton?

  override func viewDidLoad() {
    super.viewDidLoad()
    preferredWidth = 320

    let titleLabel = UILabel()
    titleLabel.text = "How was your visit?"
    titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0

    let messageLabel = UILabel()
    messageLabel.text = "Your feedback helps us improve the demo experience."
    messageLabel.font = .preferredFont(forTextStyle: .subheadline)
    messageLabel.textColor = .secondaryLabel
    messageLabel.textAlignment = .center
    messageLabel.numberOfLines = 0

    rating.configuration.layout.itemSize = CGSize(width: 32, height: 32)
    rating.configuration.interaction.touchHaptic = .selection
    rating.onValueChanged = { [weak self] value in
      self?.submitButton?.isEnabled = value > 0
    }

    let submit = UIButton(type: .system)
    submit.configuration = .filled()
    submit.configuration?.cornerStyle = .large
    submit.setTitle("Submit", for: .normal)
    submit.isEnabled = false
    submit.addAction(UIAction { [weak self] _ in self?.submitRating() }, for: .touchUpInside)
    submitButton = submit

    let cancel = UIButton(type: .system)
    cancel.configuration = .gray()
    cancel.configuration?.cornerStyle = .large
    cancel.setTitle("Maybe later", for: .normal)
    cancel.addAction(UIAction { [weak self] _ in self?.dismissSheet() }, for: .touchUpInside)

    let ratingHost = FKRatingExampleSupport.embedRating(rating, alignment: .center)

    contentStack.addArrangedSubview(titleLabel)
    contentStack.addArrangedSubview(messageLabel)
    contentStack.addArrangedSubview(ratingHost)
    contentStack.addArrangedSubview(submit)
    contentStack.addArrangedSubview(cancel)
  }

  private func submitRating() {
    FKToast.show(
      "Thanks — you rated \(Int(rating.value)) star\(rating.value == 1 ? "" : "s").",
      style: .success
    )
    dismissSheet()
  }

  private func dismissSheet() {
    dismiss(animated: true)
  }
}

// MARK: - Feedback (center fitted)

/// Centered sheet combining ``FKRatingControl`` with a short comment field.
final class FKRatingFeedbackSheetContentViewController: FKRatingSheetContentViewController {

  private let rating = FKRatingControl.interactiveStars(value: 3, step: .half)
  private let commentView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    preferredWidth = 340

    let titleLabel = UILabel()
    titleLabel.text = "Rate your support experience"
    titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    titleLabel.numberOfLines = 0

    rating.configuration.layout.labelPlacement = .bottom
    rating.configuration.label.valuePrefix = "Score: "

    commentView.font = .preferredFont(forTextStyle: .body)
    commentView.backgroundColor = .tertiarySystemGroupedBackground
    commentView.layer.cornerRadius = 10
    commentView.layer.cornerCurve = .continuous
    commentView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
    commentView.text = "Tell us what went well or what we can improve…"
    commentView.textColor = .placeholderText
    commentView.delegate = self
    commentView.heightAnchor.constraint(equalToConstant: 96).isActive = true

    let send = UIButton(type: .system)
    send.configuration = .filled()
    send.configuration?.cornerStyle = .large
    send.setTitle("Send feedback", for: .normal)
    send.addAction(UIAction { [weak self] _ in self?.sendFeedback() }, for: .touchUpInside)

    contentStack.addArrangedSubview(titleLabel)
    contentStack.addArrangedSubview(FKRatingExampleSupport.embedRating(rating, alignment: .center))
    contentStack.addArrangedSubview(commentView)
    contentStack.addArrangedSubview(send)
  }

  private func sendFeedback() {
    let note = commentView.textColor == .placeholderText ? "" : commentView.text ?? ""
    let message = note.isEmpty
      ? "Feedback sent (\(String(format: "%.1f", rating.value))★)"
      : "Feedback sent (\(String(format: "%.1f", rating.value))★) — \(String(note.prefix(60)))"
    FKToast.show(message, style: .success)
    dismiss(animated: true)
  }
}

extension FKRatingFeedbackSheetContentViewController: UITextViewDelegate {
  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.textColor == .placeholderText {
      textView.text = ""
      textView.textColor = .label
    }
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      textView.text = "Tell us what went well or what we can improve…"
      textView.textColor = .placeholderText
    }
  }
}

// MARK: - App Store style

/// App Store–inspired in-app rating prompt inside a centered sheet.
final class FKRatingAppStoreSheetContentViewController: FKRatingSheetContentViewController {

  private let rating = FKRatingControl.interactiveStars(value: 0, step: .whole)
  private var submitButton: UIButton?

  override func viewDidLoad() {
    super.viewDidLoad()
    preferredWidth = 320

    let iconHost = FKRatingExampleSupport.centeredContainer(
      for: FKRatingSheetExampleSupport.makeAppIconView()
    )

    let appNameLabel = UILabel()
    appNameLabel.text = "FKKit Examples"
    appNameLabel.font = .preferredFont(forTextStyle: .headline)
    appNameLabel.textAlignment = .center
    appNameLabel.numberOfLines = 0

    let titleLabel = UILabel()
    titleLabel.text = "Enjoying FKKit Examples?"
    titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0

    let subtitleLabel = UILabel()
    subtitleLabel.text = "Tap a star to rate it on the App Store."
    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.numberOfLines = 0
    [appNameLabel, titleLabel, subtitleLabel].forEach {
      $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    rating.configuration.layout.itemSize = CGSize(width: 36, height: 36)
    rating.configuration.layout.itemSpacing = 10
    rating.configuration.appearance.filledColor = .systemBlue
    rating.configuration.appearance.emptyColor = .tertiaryLabel
    rating.configuration.interaction.touchHaptic = .light
    rating.onValueChanged = { [weak self] value in
      self?.submitButton?.isEnabled = value > 0
    }

    let ratingHost = FKRatingExampleSupport.embedRating(rating, alignment: .center)

    let buttons = FKRatingSheetExampleSupport.makeHorizontalButtonRow(
      leadingTitle: "Not Now",
      trailingTitle: "Submit",
      leadingAction: { [weak self] in self?.dismiss(animated: true) },
      trailingAction: { [weak self] in self?.submitToStore() }
    )
    submitButton = buttons.arrangedSubviews.compactMap { $0 as? UIButton }.last
    submitButton?.isEnabled = false

    contentStack.spacing = 14
    contentStack.addArrangedSubview(iconHost)
    contentStack.addArrangedSubview(appNameLabel)
    contentStack.addArrangedSubview(titleLabel)
    contentStack.addArrangedSubview(subtitleLabel)
    contentStack.addArrangedSubview(ratingHost)
    contentStack.addArrangedSubview(buttons)

    FKRatingSheetExampleSupport.updatePreferredContentSize(for: self, width: preferredWidth)
  }

  private func submitToStore() {
    let stars = Int(rating.value)
    FKToast.show(
      "Would open App Store review (\(stars) star\(stars == 1 ? "" : "s"))",
      style: .normal
    )
    dismiss(animated: true)
  }
}
