import FKUIKit
import UIKit

final class FKIconViewExampleContentSourcesViewController: FKIconViewExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Content sources"

    let symbol = FKIconViewExampleSupport.makeIcon(size: .m, symbolName: "creditcard.fill", tintColor: .systemIndigo)

    var templateImageConfig = FKIconViewConfiguration()
    templateImageConfig.layout.size = .m
    templateImageConfig.appearance.treatsCustomImageAsTemplate = true
    templateImageConfig.appearance.defaultTintColor = .systemPink
    let templateImage = FKIconView(configuration: templateImageConfig)
    templateImage.image = FKIconViewExampleSupport.sampleColoredGlyphImage()
    templateImage.symbolName = "star.fill"

    var originalImageConfig = FKIconViewConfiguration()
    originalImageConfig.layout.size = .m
    originalImageConfig.appearance.treatsCustomImageAsTemplate = false
    let originalImage = FKIconView(configuration: originalImageConfig)
    originalImage.image = FKIconViewExampleSupport.sampleColoredGlyphImage()

    let priority = FKIconViewExampleSupport.makeIcon(size: .m, symbolName: "heart.fill", tintColor: .systemRed)
    priority.image = FKIconViewExampleSupport.sampleColoredGlyphImage()

    let box = FKIconViewExampleSupport.sectionContainer(title: "symbolName vs image")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      "When both are set, image wins. treatsCustomImageAsTemplate = true applies iconTintColor; false preserves original colors with aspect-fit scaling."
    ))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "SF Symbol", control: symbol))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Template image", control: templateImage))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Original image", control: originalImage))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Image + symbol (image wins)", control: priority))
    contentStack.addArrangedSubview(box)
  }
}
