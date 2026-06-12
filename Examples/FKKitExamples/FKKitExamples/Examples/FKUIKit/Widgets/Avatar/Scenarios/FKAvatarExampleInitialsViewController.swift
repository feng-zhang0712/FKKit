import FKUIKit
import UIKit

final class FKAvatarExampleInitialsViewController: FKAvatarExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Initials fallback"

    contentStack.addArrangedSubview(FKAvatarExampleSupport.caption(
      "When no image is available, FKAvatar derives initials from displayName (Latin word initials or first CJK grapheme)."
    ))

    let samples: [(String, String)] = [
      ("Alex Morgan", "Latin · two word initials"),
      ("Zhang Wei", "CJK · first character"),
      ("bob", "Latin · single word"),
      ("", "Empty · person.fill placeholder"),
      ("   ", "Whitespace-only · placeholder"),
    ]

    for (name, note) in samples {
      let box = FKAvatarExampleSupport.sectionContainer(title: note)
      var config = FKAvatarConfiguration()
      config.layout.size = .l
      let avatar = FKAvatar(configuration: config)
      avatar.displayName = name.isEmpty ? nil : name
      box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
      let label = UILabel()
      label.font = .preferredFont(forTextStyle: .footnote)
      label.textColor = .tertiaryLabel
      label.text = name.isEmpty ? "(nil displayName)" : "\"\(name)\""
      box.addArrangedSubview(label)
      contentStack.addArrangedSubview(box)
    }
  }
}
