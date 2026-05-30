import UIKit
import FKUIKit

/// FKCallout builder, update, hooks, anchor alignment, and custom configuration.
final class FKCalloutAdvancedExampleViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Core API anchor")
  private var handle: FKCalloutHandle?
  private var showCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKCallout advanced"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "Exercises FKCallout.show(builder:), update, dismiss, and lifecycle hooks.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor)
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show with hooks") { [weak self] in
        self?.showWithHooks()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Update message in place") { [weak self] in
        self?.updateMessage()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Leading-aligned wide bubble") { [weak self] in
        self?.showLeadingAligned()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Custom view popover") { [weak self] in
        self?.showCustomView()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Concurrent tooltips") { [weak self] in
        self?.showConcurrentTooltips()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss via handle") { [weak self] in
        self?.handle?.dismiss()
        self?.log("FKCalloutHandle.dismiss")
      }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "Lower-level FKCallout APIs when presets are not enough.",
        body: controls
      )
    )
  }

  private func showWithHooks() {
    showCount += 1
    var config = FKCalloutConfiguration.popoverDefault(placement: .top)
    config.autoDismissDuration = nil
    var hooks = FKCalloutLifecycleHooks()
    hooks.willShow = { [weak self] _ in
      self?.log("willShow")
    }
    hooks.didShow = { [weak self] _ in
      self?.log("didShow")
    }
    hooks.willDismiss = { [weak self] _, reason in
      self?.log("willDismiss · \(reason)")
    }
    hooks.didDismiss = { [weak self] _, reason in
      self?.log("didDismiss · \(reason)")
      self?.handle = nil
    }
    handle = FKCallout.show(
      content: .message("Callout #\(showCount)"),
      anchoredTo: anchor,
      configuration: config,
      hooks: hooks
    )
    log("FKCallout.show · handle \(handle?.id.uuidString.prefix(8) ?? "nil")")
  }

  private func updateMessage() {
    guard let handle else {
      log("Show a callout first")
      return
    }
    showCount += 1
    let ok = FKCallout.update(handle.id, content: .message("Updated to #\(showCount)"))
    log(ok ? "FKCallout.update succeeded" : "FKCallout.update failed")
  }

  private func showLeadingAligned() {
    var config = FKCalloutConfiguration.popoverDefault(placement: .bottomLeading)
    config.anchorAlignment = .leading
    config.minWidth = 260
    config.appearance = FKCalloutAppearance(style: .light, borderColor: .separator, borderWidth: 1)
    handle = FKCallout.show(
      content: .message("Leading-aligned popover with border."),
      anchoredTo: anchor,
      configuration: config
    )
    log("anchorAlignment .leading · minWidth 260")
  }

  private func showCustomView() {
    handle = FKPopover.show(customView: {
      let container = UIView()
      container.translatesAutoresizingMaskIntoConstraints = false
      container.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

      let label = UILabel()
      label.text = "Custom UIView content"
      label.font = .preferredFont(forTextStyle: .body)
      label.textColor = .label
      label.textAlignment = .center
      label.numberOfLines = 0
      label.translatesAutoresizingMaskIntoConstraints = false

      container.addSubview(label)
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor),
        label.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor),
        label.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor),
        label.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor),
        container.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
      ])
      return container
    }, anchoredTo: anchor, placement: .trailing)
    log("FKPopover.show(customView:)")
  }

  private func showConcurrentTooltips() {
    var topConfig = FKCalloutConfiguration.tooltipDefault(placement: .top)
    topConfig.presentationPolicy = .allowConcurrent
    topConfig.autoDismissDuration = nil
    var bottomConfig = FKCalloutConfiguration.tooltipDefault(placement: .bottom)
    bottomConfig.presentationPolicy = .allowConcurrent
    bottomConfig.autoDismissDuration = nil
    FKTooltip.show("Concurrent tooltip · top", anchoredTo: anchor, configuration: topConfig)
    FKTooltip.show("Concurrent tooltip · bottom", anchoredTo: anchor, configuration: bottomConfig)
    log("presentationPolicy .allowConcurrent")
  }
}
