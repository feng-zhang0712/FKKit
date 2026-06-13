import FKUIKit
import UIKit

final class FKIconViewExampleEmptyContentViewController: FKIconViewExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Empty & placeholder"

    var hiddenConfig = FKIconViewConfiguration()
    hiddenConfig.layout.size = .m
    hiddenConfig.layout.emptyContentBehavior = .hidden
    hiddenConfig.appearance.backgroundStyle = .circle(fill: UIColor.secondarySystemFill)
    let hidden = FKIconView(configuration: hiddenConfig)

    var placeholderConfig = FKIconViewConfiguration()
    placeholderConfig.layout.size = .m
    placeholderConfig.layout.emptyContentBehavior = .placeholder
    placeholderConfig.appearance.backgroundStyle = .circle(fill: UIColor.secondarySystemFill)
    placeholderConfig.appearance.placeholderSymbolName = "questionmark.circle"
    placeholderConfig.appearance.defaultTintColor = .tertiaryLabel
    let placeholder = FKIconView(configuration: placeholderConfig)

    var customPlaceholderConfig = FKIconViewConfiguration()
    customPlaceholderConfig.layout.size = .l
    customPlaceholderConfig.layout.emptyContentBehavior = .placeholder
    customPlaceholderConfig.appearance.placeholderSymbolName = "photo"
    customPlaceholderConfig.appearance.defaultTintColor = .secondaryLabel
    let customPlaceholder = FKIconView(configuration: customPlaceholderConfig)

    let box = FKIconViewExampleSupport.sectionContainer(title: "FKIconViewEmptyContentBehavior")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      "Use .hidden to collapse the glyph while keeping optional background chrome. .placeholder shows placeholderSymbolName at reduced opacity (0.35)."
    ))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Hidden glyph", control: hidden))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Default placeholder", control: placeholder))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Custom placeholderSymbolName", control: customPlaceholder))
    contentStack.addArrangedSubview(box)
  }
}
