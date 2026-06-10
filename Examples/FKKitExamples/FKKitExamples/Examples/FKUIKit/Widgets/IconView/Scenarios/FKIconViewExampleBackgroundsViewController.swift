import FKUIKit
import UIKit

final class FKIconViewExampleBackgroundsViewController: FKIconViewExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Background styles"

    let none = FKIconViewExampleSupport.makeIcon(
      size: .m,
      symbolName: "wifi",
      tintColor: .label
    )

    var circleConfig = FKIconViewConfiguration()
    circleConfig.layout.size = .m
    circleConfig.appearance.backgroundStyle = .circle(fill: UIColor.systemBlue.withAlphaComponent(0.15))
    circleConfig.appearance.defaultTintColor = .systemBlue
    let circle = FKIconView(configuration: circleConfig, symbolName: "airplane")

    var roundedConfig = FKIconViewConfiguration()
    roundedConfig.layout.size = .m
    roundedConfig.appearance.backgroundStyle = .roundedRect(
      cornerRadius: 8,
      fill: UIColor.systemGreen.withAlphaComponent(0.18)
    )
    roundedConfig.appearance.defaultTintColor = .systemGreen
    let rounded = FKIconView(configuration: roundedConfig, symbolName: "leaf.fill")

    let box = FKIconViewExampleSupport.sectionContainer(title: "FKIconViewBackgroundStyle")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      ".none keeps the glyph only. .circle(fill:) is common for tinted leading icons. .roundedRect(cornerRadius:fill:) matches settings-row chrome."
    ))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "None", control: none))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Circle", control: circle))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Rounded rect", control: rounded))
    contentStack.addArrangedSubview(box)
  }
}
