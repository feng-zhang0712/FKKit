import FKUIKit
import UIKit

// MARK: - Demo URLs

enum FKCarouselExampleURLs {
  static func banner(id: Int, width: Int = 800, height: Int = 450) -> URL {
    URL(string: "https://picsum.photos/id/\(id)/\(width)/\(height)")!
  }

  static var broken: URL {
    URL(string: "https://httpbin.org/status/404")!
  }

  static let heroIDs = [101, 102, 103, 104, 105]
}

// MARK: - Slide factories

enum FKCarouselExampleSlides {
  static func heroSlides(count: Int = 5) -> [FKImageBannerSlide] {
    FKCarouselExampleURLs.heroIDs.prefix(count).enumerated().map { index, photoID in
      FKImageBannerSlide(
        id: "hero-\(index)",
        imageSource: .url(FKCarouselExampleURLs.banner(id: photoID)),
        title: "Campaign \(index + 1)",
        subtitle: "Limited-time offer",
        accessibilityLabel: "Campaign \(index + 1)",
        linkURL: URL(string: "https://example.com/promo/\(index + 1)"),
        linkOpenPolicy: .callbackOnly,
        overlayStyle: index.isMultiple(of: 2)
          ? FKImageBannerOverlayStyle(ctaTitle: "Shop now", visibility: .always)
          : nil
      )
    }
  }

  static func promoSlides(count: Int = 4) -> [FKImageBannerSlide] {
    (0 ..< count).map { index in
      FKImageBannerSlide(
        id: "peek-\(index)",
        imageSource: .url(FKCarouselExampleURLs.banner(id: 200 + index * 11, width: 640, height: 360)),
        title: "Peek \(index + 1)",
        subtitle: "Card layout",
        accessibilityLabel: "Promotion \(index + 1)"
      )
    }
  }

  static func overlayVariants() -> [FKImageBannerSlide] {
    [
      FKImageBannerSlide(
        id: "title-only",
        imageSource: .url(FKCarouselExampleURLs.banner(id: 301)),
        title: "Title only",
        subtitle: nil,
        accessibilityLabel: "Title only slide"
      ),
      FKImageBannerSlide(
        id: "title-subtitle",
        imageSource: .url(FKCarouselExampleURLs.banner(id: 302)),
        title: "Title + subtitle",
        subtitle: "Secondary line for context",
        accessibilityLabel: "Title and subtitle slide"
      ),
      FKImageBannerSlide(
        id: "with-cta",
        imageSource: .url(FKCarouselExampleURLs.banner(id: 303)),
        title: "With CTA",
        subtitle: "Tap the capsule button",
        accessibilityLabel: "Slide with call to action",
        overlayStyle: FKImageBannerOverlayStyle(ctaTitle: "Explore", visibility: .always)
      ),
      FKImageBannerSlide(
        id: "a11y-only",
        imageSource: .url(FKCarouselExampleURLs.banner(id: 304)),
        title: "Accessibility only overlay",
        subtitle: "Hidden visually",
        accessibilityLabel: "Accessibility only overlay",
        overlayStyle: FKImageBannerOverlayStyle(visibility: .accessibilityOnly)
      ),
    ]
  }

  static func failureSlides() -> [FKImageBannerSlide] {
    [
      FKImageBannerSlide(
        id: "good",
        imageSource: .url(FKCarouselExampleURLs.banner(id: 401)),
        title: "Valid image",
        accessibilityLabel: "Valid image slide"
      ),
      FKImageBannerSlide(
        id: "bad",
        imageSource: .url(FKCarouselExampleURLs.broken),
        title: "Broken URL",
        accessibilityLabel: "Broken image slide"
      ),
      FKImageBannerSlide(
        id: "local",
        imageSource: .image(makeLocalPlaceholderImage()),
        title: "In-memory image",
        accessibilityLabel: "Local in-memory slide"
      ),
    ]
  }

  static func makeLocalPlaceholderImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 180))
    return renderer.image { context in
      UIColor.systemTeal.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 320, height: 180))
      let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 20),
        .foregroundColor: UIColor.white,
      ]
      "Local".draw(at: CGPoint(x: 120, y: 78), withAttributes: attrs)
    }
  }
}

// MARK: - Layout helpers

enum FKCarouselExampleSupport {
  static func makeRootScrollStack() -> (UIScrollView, UIStackView) {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)
    return (scrollView, stack)
  }

  static func pinScrollView(_ scrollView: UIScrollView, contentStack: UIStackView, in view: UIView) {
    view.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])
  }

  static func captionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func sectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.text = text
    return label
  }

  static func makeActionButton(_ title: String, handler: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.backgroundColor = .secondarySystemFill
    button.layer.cornerRadius = 8
    button.heightAnchor.constraint(equalToConstant: 40).isActive = true
    button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
    return button
  }

  static func makeEventLogView() -> UITextView {
    let view = UITextView()
    view.isEditable = false
    view.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    view.backgroundColor = .secondarySystemBackground
    view.layer.cornerRadius = 8
    view.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalToConstant: 140).isActive = true
    return view
  }

  static func appendEvent(_ message: String, to log: UITextView) {
    let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    let line = "[\(stamp)] \(message)\n"
    log.text = line + (log.text ?? "")
  }

  static func onboardingItems() -> [FKCarouselItem] {
    [
      FKCarouselItem(id: "welcome", accessibilityLabel: "Welcome"),
      FKCarouselItem(id: "discover", accessibilityLabel: "Discover features"),
      FKCarouselItem(id: "start", accessibilityLabel: "Get started"),
    ]
  }

  static func makeOnboardingPage(item: FKCarouselItem, bounds: CGRect) -> UIView {
    let container = UIView(frame: bounds)
    container.backgroundColor = .secondarySystemGroupedBackground
    container.layer.cornerRadius = 12

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false

    let title = UILabel()
    title.font = .preferredFont(forTextStyle: .title2)
    title.text = item.accessibilityLabel
    title.textAlignment = .center

    let body = UILabel()
    body.font = .preferredFont(forTextStyle: .body)
    body.textColor = .secondaryLabel
    body.numberOfLines = 0
    body.textAlignment = .center
    body.text = "Custom UIView page via pageProvider."

    stack.addArrangedSubview(title)
    stack.addArrangedSubview(body)
    container.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
    ])
    return container
  }
}

@MainActor
class FKCarouselExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  init() {
    let pair = FKCarouselExampleSupport.makeRootScrollStack()
    scrollView = pair.0
    contentStack = pair.1
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func installScrollRootChrome() {
    view.backgroundColor = .systemGroupedBackground
    FKCarouselExampleSupport.pinScrollView(scrollView, contentStack: contentStack, in: view)
  }
}
