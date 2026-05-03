import FKUIKit
import UIKit

fileprivate struct FKProgressBarGalleryRow {
  let title: String
  let subtitle: String
  let configuration: FKProgressBarConfiguration
  let progress: CGFloat
  let buffer: CGFloat
  let indeterminate: Bool
}

/// Matches ``FKProgressBar`` layout rules closely enough for table rows: fixed height must cover track/ring **and** any label that extends outside the track rect.
fileprivate enum FKProgressBarGalleryBarHeight {
  static func required(for c: FKProgressBarConfiguration) -> CGFloat {
    let ins = c.contentInsets
    let lh = ceil(c.labelFont.lineHeight)
    let pad = c.labelPadding

    switch c.variant {
    case .ring:
      let d = c.ringDiameter ?? 36
      // Extra vertical room so stroke + optional label are not clipped by the fixed row height.
      let strokeSlop = c.ringLineWidth * 2 + 8
      var labelExtra: CGFloat = 0
      switch c.labelPlacement {
      case .above, .below:
        labelExtra = lh + pad * 2
      case .centeredOnTrack:
        labelExtra = lh + pad
      case .leading, .trailing:
        labelExtra = max(0, lh + pad * 2 - d * 0.25)
      case .none:
        break
      }
      return max(52, d + ins.top + ins.bottom + labelExtra + strokeSlop)

    case .linear:
      if c.axis == .vertical {
        return 152
      }
      var h = c.trackThickness + ins.top + ins.bottom + 6
      switch c.labelPlacement {
      case .above, .below:
        h += lh + pad * 2
      case .leading, .trailing:
        h = ins.top + ins.bottom + max(c.trackThickness, lh + pad * 2)
      case .centeredOnTrack:
        h = ins.top + ins.bottom + max(c.trackThickness, lh + pad)
      case .none:
        break
      }
      return max(28, h)
    }
  }
}

/// Side-by-side presets illustrating common ``FKProgressBar`` product patterns (buffered download, stepped install, ring activity, etc.).
final class FKProgressBarGalleryDemoViewController: UITableViewController {

  /// Slightly inset track/ring inside the bar so labels and strokes are not clipped at the cell edge.
  private enum GalleryChrome {
    static func apply(_ c: inout FKProgressBarConfiguration) {
      c.contentInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    }
  }

  /// Width that matches ``FKProgressBar`` ring intrinsic layout (diameter + centered label band + insets + stroke slop).
  fileprivate static func galleryRingControlWidth(for c: FKProgressBarConfiguration) -> CGFloat {
    let d = CGFloat(c.ringDiameter ?? 36)
    let ins = c.contentInsets
    let strokeSlop = c.ringLineWidth + 8
    var centeredLabel: CGFloat = 0
    if c.labelPlacement == .centeredOnTrack {
      centeredLabel = ceil(c.labelFont.lineHeight) + c.labelPadding
    }
    return d + centeredLabel + ins.left + ins.right + strokeSlop
  }

  /// Row height that matches ``GalleryCell`` constraints (title + subtitle + bar + layout margins). Required so UITableView does not apply a transient `Encapsulated-Layout-Height` of 44pt, which conflicts with the vertical chain.
  private static func galleryRowHeight(for row: FKProgressBarGalleryRow, tableViewWidth: CGFloat) -> CGFloat {
    let w = max(1, tableViewWidth)
    // Inset grouped: leave room for section side insets and cell margins.
    let labelWidth = max(160, w - 40)
    let titleFont = UIFont.preferredFont(forTextStyle: .headline)
    let subFont = UIFont.preferredFont(forTextStyle: .footnote)
    let titleH = ceil(
      (row.title as NSString).boundingRect(
        with: CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: titleFont],
        context: nil
      ).height
    )
    let subH = ceil(
      (row.subtitle as NSString).boundingRect(
        with: CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: subFont],
        context: nil
      ).height
    )
    let barTop: CGFloat = row.configuration.variant == .ring ? 20 : 12
    let barH = FKProgressBarGalleryBarHeight.required(for: row.configuration)
    let inner = titleH + 4 + subH + barTop + barH
    // Matches typical `UITableViewCell` contentView ↔ `layoutMarginsGuide` vertical spacing (see `UIView-topMargin-guide-constraint` / bottom in logs).
    let marginGuideVerticalGutter: CGFloat = 8 + 8
    return inner + marginGuideVerticalGutter
  }

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Builds rows with `var` mutations so we stay compatible with Swift 6 memberwise `init` argument ordering on ``FKProgressBarConfiguration``.
  private lazy var rows: [FKProgressBarGalleryRow] = Self.buildGalleryRows()

  private static func buildGalleryRows() -> [FKProgressBarGalleryRow] {
    var out: [FKProgressBarGalleryRow] = []

    do {
      var c = FKProgressBarConfiguration()
      c.showsBuffer = false
      c.labelPlacement = .none
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Default horizontal",
        subtitle: "Baseline system colors, no buffer.",
        configuration: c,
        progress: 0.42,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.bufferColor = UIColor.systemBlue.withAlphaComponent(0.28)
      c.showsBuffer = true
      c.labelPlacement = .below
      c.labelFormat = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Buffered stream",
        subtitle: "Primary + buffer fills (media / large file UX).",
        configuration: c,
        progress: 0.38,
        buffer: 0.76,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.trackThickness = 8
      c.fillStyle = .gradientAlongProgress
      c.progressColor = .systemIndigo
      c.progressGradientEndColor = .systemCyan
      c.prefersSpringAnimation = true
      c.animationDuration = 0.55
      c.labelPlacement = .trailing
      c.labelFormat = .percentFractional
      c.labelFractionDigits = 1
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Gradient + spring",
        subtitle: "FillStyle.gradientAlongProgress + spring motion.",
        configuration: c,
        progress: 0.67,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.trackThickness = 10
      c.segmentCount = 10
      c.segmentGapFraction = 0.1
      c.linearCapStyle = .round
      c.labelPlacement = .above
      c.labelFormat = .normalizedValue
      c.labelFractionDigits = 2
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Segmented (10)",
        subtitle: "Discrete chunks for multi-step installers.",
        configuration: c,
        progress: 0.5,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.axis = .vertical
      c.trackThickness = 10
      c.showsBuffer = true
      c.labelPlacement = .leading
      c.labelFormat = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Vertical axis",
        subtitle: "Tall layout: intrinsic width, flexible height.",
        configuration: c,
        progress: 0.55,
        buffer: 0.8,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.variant = .ring
      c.ringLineWidth = 6
      c.ringDiameter = 88
      c.fillStyle = .gradientAlongProgress
      c.progressColor = .systemPurple
      c.progressGradientEndColor = .systemPink
      c.labelPlacement = .centeredOnTrack
      c.labelFormat = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Ring determinate",
        subtitle: "Circular stroke; gradient fill approximated on ring.",
        configuration: c,
        progress: 0.73,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.variant = .ring
      c.ringLineWidth = 5
      c.ringDiameter = 96
      c.trackColor = .tertiarySystemFill
      c.bufferColor = UIColor.systemGreen.withAlphaComponent(0.35)
      c.progressColor = .systemGreen
      c.showsBuffer = true
      c.labelPlacement = .centeredOnTrack
      c.labelFormat = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Ring + buffer",
        subtitle: "Buffered arc behind primary stroke.",
        configuration: c,
        progress: 0.4,
        buffer: 0.65,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.trackThickness = 6
      c.indeterminateStyle = .marquee
      c.indeterminatePeriod = 1.1
      c.labelPlacement = .none
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Indeterminate marquee (linear)",
        subtitle: "Activity without numeric progress.",
        configuration: c,
        progress: 0,
        buffer: 0,
        indeterminate: true
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.variant = .ring
      c.ringLineWidth = 5
      c.ringDiameter = 100
      c.indeterminateStyle = .breathing
      c.indeterminatePeriod = 1.4
      c.labelPlacement = .centeredOnTrack
      c.labelFormat = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Indeterminate breathing (ring)",
        subtitle: "Soft opacity pulse on ring track.",
        configuration: c,
        progress: 0.2,
        buffer: 0,
        indeterminate: true
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.labelPlacement = .centeredOnTrack
      c.labelFormat = .logicalRangeValue
      c.logicalMinimum = 0
      c.logicalMaximum = 512
      c.labelPrefix = ""
      c.labelSuffix = " MB"
      c.labelUsesSemanticLabelColor = true
      let f = NumberFormatter()
      f.numberStyle = .decimal
      f.maximumFractionDigits = 0
      c.numberFormatter = f
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Logical range label",
        subtitle: "Maps 0…1 to MB with prefix/suffix.",
        configuration: c,
        progress: 0.3125,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.trackThickness = 6
      c.trackCornerRadius = 2
      c.linearCapStyle = .square
      c.trackBorderWidth = 1
      c.trackBorderColor = .separator
      c.progressBorderWidth = 1
      c.progressBorderColor = .label
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Borders + square caps",
        subtitle: "Outlined track and progress for dense dashboards.",
        configuration: c,
        progress: 0.88,
        buffer: 0,
        indeterminate: false
      ))
    }

    return out
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Preset gallery"
    tableView.register(GalleryCell.self, forCellReuseIdentifier: GalleryCell.reuseId)
    tableView.estimatedRowHeight = 140
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let row = rows[indexPath.row]
    let tw = tableView.bounds.width > 1 ? tableView.bounds.width : UIScreen.main.bounds.width
    return Self.galleryRowHeight(for: row, tableViewWidth: tw)
  }

  override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    let row = rows[indexPath.row]
    let tw = tableView.bounds.width > 1 ? tableView.bounds.width : UIScreen.main.bounds.width
    return Self.galleryRowHeight(for: row, tableViewWidth: tw)
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: GalleryCell.reuseId, for: indexPath) as! GalleryCell
    let row = rows[indexPath.row]
    cell.configure(row: row)
    return cell
  }
}

// MARK: - Cell

private final class GalleryCell: UITableViewCell {
  static let reuseId = "GalleryCell"

  private let bar = FKProgressBar()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private var barHeightConstraint: NSLayoutConstraint!
  private var barWidthToMargins: NSLayoutConstraint!
  private var verticalBarWidth: NSLayoutConstraint?
  private var ringBarWidth: NSLayoutConstraint?
  private var barTopToSubtitle: NSLayoutConstraint!

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    contentView.clipsToBounds = true
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0
    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    [titleLabel, subtitleLabel, bar].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    contentView.addSubview(titleLabel)
    contentView.addSubview(subtitleLabel)
    contentView.addSubview(bar)
    barHeightConstraint = bar.heightAnchor.constraint(equalToConstant: 44)
    barHeightConstraint.priority = UILayoutPriority(999)
    barWidthToMargins = bar.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.86)
    barTopToSubtitle = bar.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

      barTopToSubtitle,
      bar.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      barWidthToMargins,
      bar.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
      barHeightConstraint,
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Stop CA indeterminate animations and reset values so the next row does not inherit layers or timing state.
    bar.stopIndeterminate()
    bar.isIndeterminate = false
    bar.setProgress(0, buffer: 0, animated: false)
    verticalBarWidth?.isActive = false
    verticalBarWidth = nil
    ringBarWidth?.isActive = false
    ringBarWidth = nil
    barWidthToMargins.isActive = true
    barTopToSubtitle.constant = 12
    titleLabel.text = nil
    subtitleLabel.text = nil
  }

  func configure(row: FKProgressBarGalleryRow) {
    titleLabel.text = row.title
    subtitleLabel.text = row.subtitle

    let c = row.configuration
    verticalBarWidth?.isActive = false
    verticalBarWidth = nil
    ringBarWidth?.isActive = false
    ringBarWidth = nil
    barTopToSubtitle.constant = c.variant == .ring ? 20 : 12

    if c.variant == .ring {
      barWidthToMargins.isActive = false
      let rw = FKProgressBarGalleryDemoViewController.galleryRingControlWidth(for: c)
      let nw = bar.widthAnchor.constraint(equalToConstant: rw)
      nw.priority = .required
      nw.isActive = true
      ringBarWidth = nw
    } else if c.variant == .linear, c.axis == .vertical {
      barWidthToMargins.isActive = false
      let w = c.trackThickness + c.contentInsets.left + c.contentInsets.right + 56
      let nw = bar.widthAnchor.constraint(equalToConstant: w)
      nw.priority = .required
      nw.isActive = true
      verticalBarWidth = nw
    } else {
      barWidthToMargins.isActive = true
    }

    bar.configuration = row.configuration
    bar.setProgress(row.progress, buffer: row.buffer, animated: false)
    bar.isIndeterminate = row.indeterminate

    barHeightConstraint.constant = FKProgressBarGalleryBarHeight.required(for: c)
    setNeedsLayout()
    layoutIfNeeded()
  }
}
