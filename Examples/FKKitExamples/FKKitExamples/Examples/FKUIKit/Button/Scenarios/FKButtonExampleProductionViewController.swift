import UIKit
import FKUIKit

/// Production-oriented FKButton patterns: touch targets, batch state APIs, loading polish, badges, symbol effects, and transient results.
final class FKButtonExampleProductionViewController: FKButtonExampleScrollViewController {

  override var pageIntroduction: String? {
    "Production patterns: HIG touch targets, batch state registration, loading customization, badge integration, symbol effects, and transient feedback."
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addExampleSection(title: "Minimum touch target", content: makeMinimumTouchTargetExample())
    addExampleSection(title: "Batch state APIs", content: makeBatchStateExample())
    addExampleSection(title: "Loading polish", content: makeLoadingPolishExample())
    addExampleSection(title: "Badge on button", content: makeBadgeExample())
    addExampleSection(title: "Symbol effects", content: makeSymbolEffectExample())
    addExampleSection(title: "Transient result", content: makeTransientResultExample())
  }

  private func makeMinimumTouchTargetExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let small = FKButton()
    small.content = .imageOnly
    small.setCenterImage(.init(systemName: "ellipsis", tintColor: .label, fixedSize: CGSize(width: 18, height: 18)), for: .normal)
    small.setAppearances(.init(normal: .ghost(cornerStyle: .init(corner: .fixed(6)))))
    small.minimumTouchTargetSize = CGSize(width: 44, height: 44)
    small.widthAnchor.constraint(equalToConstant: 24).isActive = true
    small.heightAnchor.constraint(equalToConstant: 24).isActive = true
    addTap(small, name: "Minimum touch target")

    stack.addArrangedSubview(captionLabel("Visual size is 24×24pt; `minimumTouchTargetSize` expands the hit area to 44×44pt."))
    stack.addArrangedSubview(horizontallyCentered(small))
    return stack
  }

  private func makeBatchStateExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let appearances = makeStatefulAppearance(
      normal: .init(foregroundColor: .label, backgroundColor: .tertiarySystemBackground, borderColor: .separator, shadow: nil),
      selected: .init(foregroundColor: .white, backgroundColor: .systemBlue, borderColor: .clear, shadow: nil),
      highlighted: .init(foregroundColor: .white, backgroundColor: .systemBlue.withAlphaComponent(0.85), borderColor: .clear, shadow: nil),
      disabled: .init(foregroundColor: .tertiaryLabel, backgroundColor: .tertiarySystemBackground, borderColor: .separator, shadow: nil)
    )

    let button = FKButton()
    button.content = .textOnly
    button.setTitles([
      (.normal, .init(text: "Batch configured", font: .systemFont(ofSize: 14, weight: .semibold), color: appearances.normalForegroundColor)),
      (.selected, .init(text: "Selected", font: .systemFont(ofSize: 14, weight: .semibold), color: appearances.selectedForegroundColor)),
      (.disabled, .init(text: "Disabled", font: .systemFont(ofSize: 14, weight: .semibold), color: appearances.disabledForegroundColor)),
    ])
    button.registerAppearances([
      (.normal, appearances.normal),
      (.selected, appearances.selected),
      (.highlighted, appearances.highlighted),
      (.disabled, appearances.disabled),
    ])
    button.heightAnchor.constraint(equalToConstant: FKButtonExampleSupport.Metrics.buttonHeight).isActive = true
    button.widthAnchor.constraint(equalToConstant: 220).isActive = true
    addTapToggleSelected(button, name: "Batch state")

    let disableToggle = UIButton(type: .system)
    disableToggle.setTitle("Toggle enabled", for: .normal)
    disableToggle.addAction(UIAction { [weak button] _ in
      guard let button else { return }
      button.isEnabled.toggle()
    }, for: .touchUpInside)

    stack.addArrangedSubview(captionLabel("`setTitles` and `registerAppearances` register multiple states in one pass."))
    stack.addArrangedSubview(horizontallyCentered(button))
    stack.addArrangedSubview(fullWidthLayoutWrapping(disableToggle))
    return stack
  }

  private func makeLoadingPolishExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let button = FKButton()
    button.content = .textOnly
    button.setTitle(.init(text: "Submit payment", font: .systemFont(ofSize: 15, weight: .semibold), color: .white), for: .normal)
    button.setAppearances(.init(normal: .filled(backgroundColor: .systemIndigo, cornerStyle: .init(corner: .fixed(12)))))
    button.loadingIndicatorConfiguration = .init(style: .medium, scale: 1.15, color: .white)
    button.loadingPresentationStyle = .replacesContent(.init(
      message: FKUIKitI18n.string("fkuikit.button.loading"),
      messageFont: .systemFont(ofSize: 14, weight: .medium),
      messageColor: .white
    ))
    button.loadingPreservesIntrinsicWidth = true
    button.heightAnchor.constraint(equalToConstant: 48).isActive = true
    button.widthAnchor.constraint(equalToConstant: 260).isActive = true

    button.addAction(UIAction { [weak self, weak button] _ in
      guard let button else { return }
      Task { @MainActor in
        await button.performWhileLoading {
          try? await Task.sleep(nanoseconds: 1_500_000_000)
        }
        self?.recordExampleTap("Loading polish")
      }
    }, for: .touchUpInside)

    stack.addArrangedSubview(captionLabel("Large spinner tint, replacement message, and `loadingPreservesIntrinsicWidth` keep the button width stable."))
    stack.addArrangedSubview(horizontallyCentered(button))
    return stack
  }

  private func makeBadgeExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let button = FKButton()
    button.content = .textAndImage(.leading)
    button.setTitle(.init(text: "Inbox", font: .systemFont(ofSize: 15, weight: .semibold), color: .label), for: .normal)
    button.setLeadingImage(.init(systemName: "tray.fill", tintColor: .systemBlue), for: .normal)
    button.setAppearances(.init(normal: .init(cornerStyle: .init(corner: .fixed(12)), border: .custom(color: .separator, width: 1), backgroundColor: .secondarySystemBackground)))
    button.heightAnchor.constraint(equalToConstant: 48).isActive = true
    button.widthAnchor.constraint(equalToConstant: 160).isActive = true
    addTap(button, name: "Badge on button")

    let badge = button.configureBadge(anchor: .topTrailing, offset: UIOffset(horizontal: 4, vertical: -4))
    badge.showCount(3, animated: false)

    stack.addArrangedSubview(captionLabel("Use `configureBadge(anchor:offset:)` then `FKBadgeController` APIs (same storage as `fk_badge`)."))
    stack.addArrangedSubview(horizontallyCentered(button))
    return stack
  }

  private func makeSymbolEffectExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let button = FKButton()
    button.content = .textAndImage(.leading)
    button.setLeadingImages([
      (.normal, .init(
        systemName: "heart",
        tintColor: .systemPink,
        symbolEffect: .init(effect: .bounce, trigger: .onStateChange)
      )),
      (.selected, .init(
        systemName: "heart.fill",
        tintColor: .systemPink,
        symbolEffect: .init(effect: .bounce, trigger: .onStateChange)
      )),
    ])
    button.setTitles([
      (.normal, .init(text: "Favorite", font: .systemFont(ofSize: 15, weight: .semibold), color: .label)),
      (.selected, .init(text: "Favorited", font: .systemFont(ofSize: 15, weight: .semibold), color: .systemPink)),
    ])
    button.registerAppearances([
      (.normal, .init(cornerStyle: .init(corner: .fixed(12)), border: .custom(color: .separator, width: 1), backgroundColor: .secondarySystemBackground)),
      (.selected, .init(cornerStyle: .init(corner: .fixed(12)), border: .custom(color: UIColor.systemPink.withAlphaComponent(0.35), width: 1), backgroundColor: UIColor.systemPink.withAlphaComponent(0.12))),
    ])
    button.heightAnchor.constraint(equalToConstant: 48).isActive = true
    button.widthAnchor.constraint(equalToConstant: 180).isActive = true
    addTapToggleSelected(button, name: "Symbol effect")

    stack.addArrangedSubview(captionLabel("Symbol effects require iOS 17+. Toggle selected to see the bounce on the heart icon."))
    stack.addArrangedSubview(horizontallyCentered(button))
    return stack
  }

  private func makeTransientResultExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let success = makeTransientButton(title: "Run success", color: .systemGreen) { button in
      await button.showTransientResult(.success, duration: 1.0, options: .init(message: "Saved"))
    }
    let failure = makeTransientButton(title: "Run failure", color: .systemRed) { button in
      await button.showTransientResult(.failure, duration: 1.0, options: .init(message: "Try again"))
    }

    stack.addArrangedSubview(captionLabel("`showTransientResult` briefly replaces content with a result icon and message."))
    stack.addArrangedSubview(horizontallyCentered(success))
    stack.addArrangedSubview(horizontallyCentered(failure))
    return stack
  }

  private func makeTransientButton(
    title: String,
    color: UIColor,
    action: @escaping @MainActor (FKButton) async -> Void
  ) -> FKButton {
    let button = FKButton()
    button.content = .textOnly
    button.setTitle(.init(text: title, font: .systemFont(ofSize: 14, weight: .semibold), color: .white), for: .normal)
    button.setAppearances(.init(normal: .filled(backgroundColor: color, cornerStyle: .init(corner: .fixed(10)))))
    button.heightAnchor.constraint(equalToConstant: FKButtonExampleSupport.Metrics.buttonHeight).isActive = true
    button.widthAnchor.constraint(equalToConstant: 200).isActive = true
    button.addAction(UIAction { [weak self, weak button] _ in
      guard let button else { return }
      Task { @MainActor in
        await action(button)
        self?.recordExampleTap(title)
      }
    }, for: .touchUpInside)
    return button
  }
}
