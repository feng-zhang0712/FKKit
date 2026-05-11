import FKCompositeKit
import UIKit

/// Demonstrates ``FKBaseViewController`` capabilities used by most app screens.
final class FKBaseViewControllerExampleViewController: FKBaseViewController {

  private let stackView = UIStackView()
  private let keyboardField = UITextField()
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBaseViewController"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "BackBtn",
      style: .plain,
      target: self,
      action: #selector(applyCustomBackButton)
    )
  }

  override func setupUI() {
    dismissKeyboardOnTapEnabled = true
    disableScrollViewBounceByDefault = true
    keyboardObservationEnabled = true
    navigationBarVisibility = .visible
    navigationBarStyle = .system
    debugLifecycleLoggingEnabled = true
    logHandler = { event, params in
      print("[FKBaseVC Demo] \(event): \(params)")
    }

    stackView.axis = .vertical
    stackView.spacing = 10
    stackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stackView)

    statusLabel.numberOfLines = 0
    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.text = "First-appear: see console for loadInitialContent + viewDidAppearForTheFirstTime (debug logs on)."
    stackView.addArrangedSubview(statusLabel)

    keyboardField.borderStyle = .roundedRect
    keyboardField.placeholder = "Tap here, then tap outside to dismiss keyboard"
    stackView.addArrangedSubview(keyboardField)

    let chrome: [(String, Selector)] = [
      ("Nav style: system", #selector(setNavSystem)),
      ("Nav style: opaque default", #selector(setNavOpaque)),
      ("Nav style: transparent", #selector(setNavTransparent)),
      ("Large titles: toggle", #selector(toggleLargeTitles)),
    ]
    chrome.forEach { stackView.addArrangedSubview(makeButton(title: $0.0, action: $0.1)) }

    let actions: [(String, Selector)] = [
      ("Show Loading (1.2s)", #selector(handleShowLoading)),
      ("Show Empty", #selector(handleShowEmpty)),
      ("Show Error + Retry", #selector(handleShowError)),
      ("Hide All State Views", #selector(handleHideAllStates)),
      ("Show Toast", #selector(handleShowToast)),
      ("Disable interactive pop", #selector(handleDisablePopGesture)),
      ("Enable interactive pop", #selector(handleEnablePopGesture)),
    ]
    actions.forEach { stackView.addArrangedSubview(makeButton(title: $0.0, action: $0.1)) }
  }

  override func setupConstraints() {
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  override func setupBindings() {}

  override func loadInitialContent() {
    super.loadInitialContent()
    print("[FKBaseVC Demo] loadInitialContent() — runs once before first viewDidAppearForTheFirstTime")
  }

  override func viewDidAppearForTheFirstTime(_ animated: Bool) {
    super.viewDidAppearForTheFirstTime(animated)
    print("[FKBaseVC Demo] viewDidAppearForTheFirstTime(animated: \(animated))")
  }

  override func keyboardWillChange(to frame: CGRect, duration: TimeInterval, curve: UIView.AnimationCurve) {
    showToast("Keyboard height: \(Int(frame.height)) pt")
  }

  override func keyboardWillHide(duration: TimeInterval, curve: UIView.AnimationCurve) {
    showToast("Keyboard hidden")
  }

  private func makeButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.configuration = .filled()
    button.configuration?.title = title
    button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  @objc private func applyCustomBackButton() {
    configureBackButton(title: "Back")
    showToast("Custom back button applied")
  }

  @objc private func setNavSystem() {
    navigationBarStyle = .system
    showToast("navigationBarStyle = .system (no appearance override)")
  }

  @objc private func setNavOpaque() {
    navigationBarStyle = .opaqueDefault
    showToast("navigationBarStyle = .opaqueDefault")
  }

  @objc private func setNavTransparent() {
    navigationBarStyle = .transparent
    showToast("navigationBarStyle = .transparent")
  }

  @objc private func toggleLargeTitles() {
    if prefersLargeTitlesWhileVisible == true {
      prefersLargeTitlesWhileVisible = nil
      showToast("Large titles: default (nil)")
    } else {
      prefersLargeTitlesWhileVisible = true
      showToast("Large titles: on while visible")
    }
  }

  @objc private func handleShowLoading() {
    showLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      self?.hideLoading()
    }
  }

  @objc private func handleShowEmpty() {
    showEmptyView(message: "No list data. Pull to refresh or change filters.")
  }

  @objc private func handleShowError() {
    showErrorView(message: "Request failed. Try again.", retryTitle: "Retry") { [weak self] in
      self?.showToast("Retry tapped")
      self?.hideErrorView()
    }
  }

  @objc private func handleHideAllStates() {
    hideLoading()
    hideEmptyView()
    hideErrorView()
  }

  @objc private func handleShowToast() {
    showToast("Toast via FKToast from FKBaseViewController.")
  }

  @objc private func handleDisablePopGesture() {
    disablesInteractivePopGesture = true
    showToast("Interactive pop gesture disabled")
  }

  @objc private func handleEnablePopGesture() {
    disablesInteractivePopGesture = false
    showToast("Interactive pop gesture enabled")
  }
}
