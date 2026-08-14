import FKUIKit
import UIKit

/// radio.group.subtitle.
final class FKRadioGroupExampleSubtitleViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Subtitles"

    let group = FKRadioGroup(options: [
      FKRadioOption(id: "basic", title: "Basic", subtitle: "Core features for individuals"),
      FKRadioOption(id: "pro", title: "Pro", subtitle: "Collaboration tools and priority support"),
      FKRadioOption(id: "team", title: "Team", subtitle: "Admin controls and shared workspaces"),
    ])
    group.selectedOptionID = "pro"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Plan comparison")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Each option can carry a footnote-style subtitle."))
    box.addArrangedSubview(group)
    contentStack.addArrangedSubview(box)
  }
}
