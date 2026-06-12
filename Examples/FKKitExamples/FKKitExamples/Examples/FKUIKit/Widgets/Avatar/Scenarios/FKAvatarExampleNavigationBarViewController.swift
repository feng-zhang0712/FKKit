import FKUIKit
import UIKit

/// Embeds a size-S avatar in the navigation bar and visualizes the 44×44 pt hit area.
final class FKAvatarExampleNavigationBarViewController: UIViewController {

  private let hitAreaView = UIView()
  private let avatar = FKAvatar()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Navigation bar"
    view.backgroundColor = .systemGroupedBackground

    var config = FKAvatarConfiguration()
    config.layout.size = .s
    config.interaction.expandsHitAreaToMinimumSize = true
    config.interaction.minimumHitAreaSize = CGSize(width: 44, height: 44)
    avatar.configuration = config
    avatar.displayName = "You"
    avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 67, size: 96), placeholder: nil)
    avatar.addAction(UIAction { [weak self] _ in
      self?.showTapAlert()
    }, for: .touchUpInside)

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "info.circle"),
      primaryAction: UIAction { [weak self] _ in self?.showTapAlert() },
      menu: nil
    )

    let barAvatar = UIBarButtonItem(customView: avatar)
    navigationItem.leftBarButtonItem = barAvatar

    let box = UIStackView()
    box.axis = .vertical
    box.spacing = 16
    box.translatesAutoresizingMaskIntoConstraints = false
    box.isLayoutMarginsRelativeArrangement = true
    box.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)

    let caption = FKAvatarExampleSupport.caption(
      "The bar button avatar uses size S (32 pt) but expands hit testing to 44×44 pt via interaction.expandsHitAreaToMinimumSize. Tap the avatar in the navigation bar."
    )
    caption.numberOfLines = 0

    hitAreaView.translatesAutoresizingMaskIntoConstraints = false
    hitAreaView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
    hitAreaView.layer.borderColor = UIColor.systemBlue.cgColor
    hitAreaView.layer.borderWidth = 1
    hitAreaView.layer.cornerRadius = 4
    hitAreaView.isUserInteractionEnabled = false

    let demoAvatar = FKAvatar(configuration: config)
    demoAvatar.displayName = "Demo"
    demoAvatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 67, size: 96), placeholder: nil)

    let host = UIView()
    host.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(hitAreaView)
    host.addSubview(demoAvatar)
    demoAvatar.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      demoAvatar.centerXAnchor.constraint(equalTo: host.centerXAnchor),
      demoAvatar.centerYAnchor.constraint(equalTo: host.centerYAnchor),
      hitAreaView.widthAnchor.constraint(equalToConstant: 44),
      hitAreaView.heightAnchor.constraint(equalToConstant: 44),
      hitAreaView.centerXAnchor.constraint(equalTo: demoAvatar.centerXAnchor),
      hitAreaView.centerYAnchor.constraint(equalTo: demoAvatar.centerYAnchor),
      host.heightAnchor.constraint(equalToConstant: 80),
    ])

    let legend = UILabel()
    legend.font = .preferredFont(forTextStyle: .footnote)
    legend.textColor = .secondaryLabel
    legend.numberOfLines = 0
    legend.text = "Blue square: minimum 44×44 pt hit target centered on the avatar."

    box.addArrangedSubview(caption)
    box.addArrangedSubview(host)
    box.addArrangedSubview(legend)
    view.addSubview(box)
    NSLayoutConstraint.activate([
      box.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      box.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      box.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  private func showTapAlert() {
    let alert = UIAlertController(title: "Avatar tapped", message: "Navigation bar avatar received the touch.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}
