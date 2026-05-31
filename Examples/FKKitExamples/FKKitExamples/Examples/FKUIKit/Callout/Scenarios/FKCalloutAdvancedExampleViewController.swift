import UIKit
import FKUIKit

/// FKCallout builder, showOrUpdate, update, hooks, anchor alignment, and custom configuration.
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
        description: "Exercises FKCalloutBuilder, showOrUpdate, FKCallout.update, lifecycle hooks, and concurrent policy.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor)
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show with hooks (builder)") { [weak self] in
        self?.showWithHooks()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("showOrUpdate message") { [weak self] in
        self?.showOrUpdateMessage()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Update via FKCallout.update") { [weak self] in
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
      FKCalloutExampleUI.button("Dismiss via FKPopover.dismiss(handle)") { [weak self] in
        guard let self, let handle = self.handle else {
          self?.log("Show a callout first")
          return
        }
        FKPopover.dismiss(handle)
        self.log("FKPopover.dismiss(handle)")
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss via FKCallout.dismiss(id)") { [weak self] in
        guard let self, let handle = self.handle else {
          self?.log("Show a callout first")
          return
        }
        FKCallout.dismiss(handle.id)
        self.log("FKCallout.dismiss(id)")
      }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "Lower-level FKCallout APIs when presets are not enough. Callouts stay open while you tap controls; use Dismiss buttons to close.",
        body: controls
      )
    )
  }

  /// Popover preset tuned for this playground: controls sit outside the bubble, so outside taps must not dismiss.
  private func playgroundConfiguration(placement: FKCalloutPlacement = .top) -> FKCalloutConfiguration {
    var config = FKCalloutConfiguration.popoverDefault(placement: placement)
    config.autoDismissDuration = nil
    config.tapOutsideToDismiss = false
    return config
  }

  private func showWithHooks() {
    showCount += 1
    let config = playgroundConfiguration(placement: .top)
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
    var builder = FKCalloutBuilder(
      content: .message("Callout #\(showCount)"),
      configuration: config,
      hooks: hooks
    )
    builder.anchorView = anchor
    handle = FKCallout.show(builder: builder)
    log("FKCallout.show(builder:) · handle \(handle?.id.uuidString.prefix(8) ?? "nil")")
  }

  private func showOrUpdateMessage() {
    showCount += 1
    let config = playgroundConfiguration(placement: .top)
    var builder = FKCalloutBuilder(
      content: .message("showOrUpdate #\(showCount)"),
      configuration: config
    )
    builder.anchorView = anchor
    handle = FKCallout.showOrUpdate(builder: builder)
    log("FKCallout.showOrUpdate · handle \(handle?.id.uuidString.prefix(8) ?? "nil")")
  }

  private func updateMessage() {
    guard let handle else {
      log("Show a callout first")
      return
    }
    showCount += 1
    let ok = FKCallout.update(handle.id, content: .message("Updated to #\(showCount)"))
    log(ok ? "FKCallout.update succeeded · Updated to #\(showCount)" : "FKCallout.update failed · callout was dismissed")
  }

  private func showLeadingAligned() {
    var config = playgroundConfiguration(placement: .bottomLeading)
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
      let label = UILabel()
      label.text = "Custom UIView content"
      label.font = .preferredFont(forTextStyle: .body)
      label.textColor = .label
      label.textAlignment = .center
      label.numberOfLines = 0
      label.translatesAutoresizingMaskIntoConstraints = false

      let container = UIView()
      container.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
      container.addSubview(label)
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor),
        label.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor),
        label.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor),
        label.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor),
      ])
      return FKCalloutExampleCustomContent.wrapping(container, width: 220)
    }, anchoredTo: anchor, placement: .trailing, configuration: playgroundConfiguration(placement: .trailing))
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
