import FKUIKit
import UIKit

final class FKIconViewExampleAccessibilityViewController: FKIconViewExampleScrollViewController {

  private let decorativeIcon = FKIconViewExampleSupport.makeIcon(
    size: .m,
    symbolName: "doc.text.fill",
    tintColor: .secondaryLabel
  )

  private let semanticIcon: FKIconView = {
    var config = FKIconViewConfiguration()
    config.layout.size = .m
    config.accessibility.isDecorative = false
    config.accessibility.customLabel = "PDF document"
    config.accessibility.customHint = "Opens the shared file"
    config.appearance.defaultTintColor = .systemRed
    return FKIconView(configuration: config, symbolName: "doc.fill")
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Accessibility"

    let box = FKIconViewExampleSupport.sectionContainer(title: "Decorative vs semantic")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      "Decorative icons (default) set accessibilityElementsHidden = true so list rows expose a single VoiceOver element. Semantic icons need isDecorative = false plus customLabel (and optional customHint)."
    ))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Decorative (hidden)", control: decorativeIcon))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Semantic label + hint", control: semanticIcon))

    let traitsLabel = FKIconViewExampleSupport.caption(
      "Semantic icon traits: .image. Enable VoiceOver and swipe to the semantic icon to hear \"PDF document. Opens the shared file.\""
    )
    contentStack.addArrangedSubview(box)
    contentStack.addArrangedSubview(traitsLabel)
  }
}
