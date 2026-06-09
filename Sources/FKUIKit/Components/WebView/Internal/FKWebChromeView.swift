import UIKit

@MainActor
protocol FKWebChromeViewDelegate: AnyObject {
  func chromeViewDidTapBack(_ chromeView: FKWebChromeView)
  func chromeViewDidTapForward(_ chromeView: FKWebChromeView)
  func chromeViewDidTapReloadOrStop(_ chromeView: FKWebChromeView)
  func chromeViewDidTapClose(_ chromeView: FKWebChromeView)
}

@MainActor
final class FKWebChromeView: UIView {
  weak var delegate: FKWebChromeViewDelegate?

  private let stackView = UIStackView()
  private let backButton = UIButton(type: .system)
  private let forwardButton = UIButton(type: .system)
  private let reloadButton = UIButton(type: .system)
  private let closeButton = UIButton(type: .system)

  private var showsCloseButton = false
  private var stackTopConstraint: NSLayoutConstraint?
  private var stackBottomConstraint: NSLayoutConstraint?
  private var buttonSizeConstraints: [NSLayoutConstraint] = []
  private var isCollapsed = true

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(mode: FKWebChromeMode) {
    switch mode {
    case .none, .custom:
      setCollapsed(true)
      isHidden = true
    case .compactToolbar(let showsClose):
      setCollapsed(false)
      isHidden = false
      showsCloseButton = showsClose
      closeButton.isHidden = !showsClose
    }
  }

  func update(canGoBack: Bool, canGoForward: Bool, isLoading: Bool) {
    guard !isCollapsed else { return }
    backButton.isEnabled = canGoBack
    forwardButton.isEnabled = canGoForward

    let reloadSymbol = isLoading ? "xmark" : "arrow.clockwise"
    reloadButton.setImage(UIImage(systemName: reloadSymbol), for: .normal)
    reloadButton.accessibilityLabel = isLoading
      ? FKUIKitI18n.string("fkuikit.webview.chrome.stop")
      : FKUIKitI18n.string("fkuikit.webview.chrome.reload")
  }

  private func setCollapsed(_ collapsed: Bool) {
    guard isCollapsed != collapsed else { return }
    isCollapsed = collapsed
    stackTopConstraint?.isActive = !collapsed
    stackBottomConstraint?.isActive = !collapsed
    for constraint in buttonSizeConstraints {
      constraint.isActive = !collapsed
    }
    isUserInteractionEnabled = !collapsed
  }

  private func commonInit() {
    backgroundColor = .secondarySystemBackground
    clipsToBounds = true

    stackView.axis = .horizontal
    stackView.alignment = .fill
    stackView.distribution = .fillEqually
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)

    configure(button: backButton, symbol: "chevron.backward", labelKey: "fkuikit.webview.chrome.back", action: #selector(backTapped))
    configure(button: forwardButton, symbol: "chevron.forward", labelKey: "fkuikit.webview.chrome.forward", action: #selector(forwardTapped))
    configure(button: reloadButton, symbol: "arrow.clockwise", labelKey: "fkuikit.webview.chrome.reload", action: #selector(reloadTapped))
    configure(button: closeButton, symbol: "xmark", labelKey: "fkuikit.webview.chrome.close", action: #selector(closeTapped))

    [backButton, forwardButton, reloadButton, closeButton].forEach(stackView.addArrangedSubview)

    stackTopConstraint = stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 4)
    stackBottomConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
    buttonSizeConstraints = [
      backButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
      backButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      forwardButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
      forwardButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      reloadButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
      reloadButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
      closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ]

    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
    ])

    isHidden = true
    closeButton.isHidden = true
    setCollapsed(true)
  }

  private func configure(button: UIButton, symbol: String, labelKey: String, action: Selector) {
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage(systemName: symbol), for: .normal)
    button.accessibilityLabel = FKUIKitI18n.string(labelKey)
    button.addTarget(self, action: action, for: .touchUpInside)
  }

  @objc private func backTapped() { delegate?.chromeViewDidTapBack(self) }
  @objc private func forwardTapped() { delegate?.chromeViewDidTapForward(self) }
  @objc private func reloadTapped() { delegate?.chromeViewDidTapReloadOrStop(self) }
  @objc private func closeTapped() { delegate?.chromeViewDidTapClose(self) }
}
