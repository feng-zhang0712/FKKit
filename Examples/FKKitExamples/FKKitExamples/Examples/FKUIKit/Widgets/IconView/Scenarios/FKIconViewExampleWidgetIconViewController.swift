import FKUIKit
import UIKit

final class FKIconViewExampleWidgetIconViewController: FKIconViewExampleScrollViewController {

  private let symbolIcon = FKIconView(configuration: FKIconViewConfiguration())
  private let imageIcon = FKIconView(configuration: FKIconViewConfiguration())
  private let clearedIcon = FKIconView(configuration: FKIconViewConfiguration())

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "WidgetIcon apply"

    symbolIcon.applyWidgetIcon(.symbol(name: "bolt.fill"))
    symbolIcon.iconTintColor = .systemYellow

    imageIcon.applyWidgetIcon(.image(FKIconViewExampleSupport.sampleColoredGlyphImage(side: 20)))
    var imageConfig = imageIcon.configuration
    imageConfig.appearance.treatsCustomImageAsTemplate = true
    imageConfig.appearance.defaultTintColor = .systemMint
    imageIcon.configuration = imageConfig

    clearedIcon.applyWidgetIcon(.symbol(name: "gear"))
    clearedIcon.applyWidgetIcon(nil)

    var clearedConfig = clearedIcon.configuration
    clearedConfig.layout.emptyContentBehavior = .placeholder
    clearedIcon.configuration = clearedConfig

    let box = FKIconViewExampleSupport.sectionContainer(title: "applyWidgetIcon(_:)")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      "Pass .symbol(name:configuration:) or .image(UIImage). Passing nil clears symbolName and image. Optional SymbolConfiguration from the payload updates appearance.symbolConfiguration."
    ))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: ".symbol", control: symbolIcon))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: ".image (template)", control: imageIcon))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "nil → placeholder", control: clearedIcon))
    contentStack.addArrangedSubview(box)
  }
}
