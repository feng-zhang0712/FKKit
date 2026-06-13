import FKUIKit
import UIKit

final class FKAvatarExampleSizesShapesViewController: FKAvatarExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Sizes & shapes"

    contentStack.addArrangedSubview(FKAvatarExampleSupport.caption(
      "FKAvatarSize presets from XS (24 pt) through XL (72 pt). Shapes: circle, squircle, rounded rectangle."
    ))

    buildSizesSection()
    buildShapesSection()
    buildLocalImageSection()
  }

  private func buildSizesSection() {
    let box = FKAvatarExampleSupport.sectionContainer(title: "Size presets")
    let row = FKAvatarExampleSupport.horizontalRow(spacing: 16)
    row.distribution = .equalSpacing

    let specs: [(FKAvatarSize, String)] = [
      (.xs, "XS"),
      (.s, "S"),
      (.m, "M"),
      (.l, "L"),
      (.xl, "XL"),
    ]

    for (size, label) in specs {
      var config = FKAvatarConfiguration()
      config.layout.size = size
      let avatar = FKAvatar(configuration: config)
      avatar.displayName = label
      avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 64, size: Int(size.diameter * 2)), placeholder: nil)

      let column = UIStackView()
      column.axis = .vertical
      column.alignment = .center
      column.spacing = 6
      column.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
      let caption = UILabel()
      caption.text = label
      caption.font = .preferredFont(forTextStyle: .caption1)
      caption.textColor = .secondaryLabel
      column.addArrangedSubview(caption)
      row.addArrangedSubview(column)
    }

    box.addArrangedSubview(row)
    contentStack.addArrangedSubview(box)
  }

  private func buildShapesSection() {
    let box = FKAvatarExampleSupport.sectionContainer(title: "Shape variants")
    let row = FKAvatarExampleSupport.horizontalRow(spacing: 20)

    let shapes: [(FKAvatarShape, String)] = [
      (.circle, "Circle"),
      (.squircle(cornerRadius: 14), "Squircle"),
      (.roundedRectangle(cornerRadius: 8), "Rounded"),
    ]

    for (shape, label) in shapes {
      var config = FKAvatarConfiguration()
      config.layout.size = .l
      config.layout.shape = shape
      let avatar = FKAvatar(configuration: config)
      avatar.displayName = label
      avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 65), placeholder: nil)

      let column = UIStackView()
      column.axis = .vertical
      column.alignment = .center
      column.spacing = 6
      column.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
      let caption = UILabel()
      caption.text = label
      caption.font = .preferredFont(forTextStyle: .caption1)
      caption.textColor = .secondaryLabel
      column.addArrangedSubview(caption)
      row.addArrangedSubview(column)
    }

    box.addArrangedSubview(row)
    contentStack.addArrangedSubview(box)
  }

  private func buildLocalImageSection() {
    let box = FKAvatarExampleSupport.sectionContainer(title: "Local UIImage")
    var config = FKAvatarConfiguration()
    config.layout.size = .l
    let avatar = FKAvatar(configuration: config)
    avatar.displayName = "Local"
    avatar.image = FKAvatarExampleSupport.makeLocalAvatarImage(label: "FK", color: .systemIndigo)
    box.addArrangedSubview(FKAvatarExampleSupport.caption("The `image` property takes precedence over `imageURL`."))
    box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
    contentStack.addArrangedSubview(box)
  }
}
