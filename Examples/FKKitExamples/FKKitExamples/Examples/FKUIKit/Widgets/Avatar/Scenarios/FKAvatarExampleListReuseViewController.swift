import FKUIKit
import UIKit

final class FKAvatarExampleListReuseViewController: UIViewController {
  private let tableView = UITableView(frame: .zero, style: .plain)
  private let names = [
    "Alex Morgan", "Sam Chen", "Jordan Lee", "Casey Kim", "Riley Park",
    "Taylor Wu", "Jamie Fox", "Morgan Blake", "Chris Diaz", "Pat Rivera",
  ]
  private var personIDs = FKAvatarExampleSupport.feedPersonIDs(count: 200)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "List reuse"
    view.backgroundColor = .systemBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(FKAvatarExampleReuseCell.self, forCellReuseIdentifier: FKAvatarExampleReuseCell.reuseID)
    tableView.dataSource = self
    tableView.rowHeight = 72
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

extension FKAvatarExampleListReuseViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    personIDs.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: FKAvatarExampleReuseCell.reuseID, for: indexPath) as! FKAvatarExampleReuseCell
    let id = personIDs[indexPath.row]
    cell.configure(
      name: names[indexPath.row % names.count],
      url: FKAvatarExampleSupport.avatarURL(id: id, size: 96)
    )
    return cell
  }
}

@MainActor
private final class FKAvatarExampleReuseCell: UITableViewCell {
  static let reuseID = "FKAvatarExampleReuseCell"

  private let avatar = FKAvatar()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    textLabel?.isHidden = true
    imageView?.isHidden = true
    detailTextLabel?.isHidden = true

    var config = FKAvatarConfiguration()
    config.layout.size = .m
    avatar.configuration = config
    let avatarDiameter = config.layout.size.diameter

    titleLabel.font = .preferredFont(forTextStyle: .body)
    subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.text = "prepareForReuse() → resetForReuse()"

    avatar.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(avatar)
    contentView.addSubview(titleLabel)
    contentView.addSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: avatarDiameter),
      avatar.heightAnchor.constraint(equalToConstant: avatarDiameter),
      titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    avatar.resetForReuse()
  }

  func configure(name: String, url: URL) {
    titleLabel.text = name
    avatar.displayName = name
    avatar.setImageURL(url, placeholder: nil)
  }
}
