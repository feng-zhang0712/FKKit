import UIKit
import FKUIKit

/// Live playground for tuning callout configuration from on-screen controls.
final class FKCalloutInteractivePlaygroundViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Interactive anchor")

  private var isDarkStyle = false
  private var isShadowEnabled = true
  private var isAutoDismissEnabled = false
  private var isTapOutsideToDismiss = true
  private var usesCustomContent = false
  private var placementIndex = 0
  private var width: Float = 280
  private var cornerRadius: Float = 16
  private var spacing: Float = 8

  private let placements: [FKCalloutPlacement] = [
    .automatic, .top, .bottom, .bottomLeading, .bottomTrailing, .leading, .trailing
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Callout playground"

    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Present", primaryAction: UIAction { [weak self] _ in
        self?.presentPreview()
      }),
      UIBarButtonItem(title: "Dismiss", primaryAction: UIAction { [weak self] _ in
        self?.dismissPreview()
      }),
    ]

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "Use the controls below to mutate the configuration, then press Present in the navigation bar to inspect the result in real time.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor, height: 220)
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 10

    controls.addArrangedSubview(FKCalloutExampleControls.segmented(title: "Placement", items: ["Auto", "Top", "Bottom", "Bottom L", "Bottom R", "Leading", "Trailing"], selectedIndex: placementIndex) { [weak self] index in
      self?.placementIndex = index
    })
    controls.addArrangedSubview(FKCalloutExampleControls.toggle(title: "Dark style", isOn: isDarkStyle) { [weak self] value in self?.isDarkStyle = value })
    controls.addArrangedSubview(FKCalloutExampleControls.toggle(title: "Shadow", isOn: isShadowEnabled) { [weak self] value in self?.isShadowEnabled = value })
    controls.addArrangedSubview(FKCalloutExampleControls.toggle(title: "Auto-dismiss", isOn: isAutoDismissEnabled) { [weak self] value in self?.isAutoDismissEnabled = value })
    controls.addArrangedSubview(FKCalloutExampleControls.toggle(title: "Tap outside to dismiss", isOn: isTapOutsideToDismiss) { [weak self] value in self?.isTapOutsideToDismiss = value })
    controls.addArrangedSubview(FKCalloutExampleControls.toggle(title: "Custom content", isOn: usesCustomContent) { [weak self] value in self?.usesCustomContent = value })
    controls.addArrangedSubview(FKCalloutExampleControls.slider(title: "Bubble width", value: width, range: 220...420, valueText: { "\(Int($0))pt" }) { [weak self] value in self?.width = value })
    controls.addArrangedSubview(FKCalloutExampleControls.slider(title: "Corner radius", value: cornerRadius, range: 8...28, valueText: { "\(Int($0))pt" }) { [weak self] value in self?.cornerRadius = value })
    controls.addArrangedSubview(FKCalloutExampleControls.slider(title: "Anchor spacing", value: spacing, range: 4...20, valueText: { "\(Int($0))pt" }) { [weak self] value in self?.spacing = value })

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Configuration controls",
        description: "This page demonstrates how switches, segments, sliders, and buttons can drive every major callout property.",
        body: controls
      )
    )
  }

  private func presentPreview() {
    var config = FKCalloutConfiguration.popoverDefault(placement: placements[placementIndex])
    config.appearance = FKCalloutAppearance(
      style: isDarkStyle ? .dark : .light,
      cornerRadius: CGFloat(cornerRadius),
      beakWidth: 16,
      beakHeight: 8,
      showsShadow: isShadowEnabled,
      shadowOpacity: 0.18,
      shadowRadius: 20,
      shadowOffset: .init(width: 0, height: 10),
      borderColor: isDarkStyle ? nil : .separator,
      borderWidth: isDarkStyle ? 0 : 0.5
    )
    config.anchorSpacing = CGFloat(spacing)
    config.maxWidth = CGFloat(width)
    config.autoDismissDuration = isAutoDismissEnabled ? 3 : nil
    config.tapOutsideToDismiss = isTapOutsideToDismiss
    config.passesThroughOutsideTouches = true

    let content: FKCalloutContent = usesCustomContent ? .customView { [weak self] in
      self?.makeCustomPreview() ?? UIView()
    } : .titleSubtitle(title: "Tooltip Title", message: "Decide who can see your information, profile, and activity on the platform.")

    FKCallout.show(content: content, anchoredTo: anchor, configuration: config)
    log(summaryText())
  }

  private func dismissPreview() {
    FKCallout.dismissActive()
    log("Dismissed active callout.")
  }

  private func makeCustomPreview() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let hero = UIView()
    hero.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.16)
    hero.layer.cornerRadius = 14
    hero.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([hero.heightAnchor.constraint(equalToConstant: 120)])

    let title = UILabel()
    title.text = "Free-form popup"
    title.font = .preferredFont(forTextStyle: .headline)
    title.numberOfLines = 0

    let body = UILabel()
    body.text = "This preview uses a custom UIView so you can validate spacing, stack order, and button layout without changing the component code."
    body.font = .preferredFont(forTextStyle: .callout)
    body.textColor = .secondaryLabel
    body.numberOfLines = 0

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    row.addArrangedSubview(FKCalloutExampleControls.calloutButton("Skip", style: .bordered()) { FKCallout.dismissActive() })
    row.addArrangedSubview(FKCalloutExampleControls.calloutButton("Continue", style: .filled()) { [weak self] in self?.log("Continue tapped") })

    stack.addArrangedSubview(hero)
    stack.addArrangedSubview(title)
    stack.addArrangedSubview(body)
    stack.addArrangedSubview(row)
    return stack
  }

  private func summaryText() -> String {
    let placement = placements[placementIndex]
    return "placement=\(placement), style=\(isDarkStyle ? "dark" : "light"), shadow=\(isShadowEnabled), autoDismiss=\(isAutoDismissEnabled), customContent=\(usesCustomContent)"
  }
}
