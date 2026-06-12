import UIKit

/// Segmented storage bar with optional legend for ``FKCellStorageSummaryCell``.
@MainActor
final class FKCellStorageProgressView: UIView {
  private let barStack = UIStackView()
  private let legendStack = UIStackView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(segments: [FKCellStorageSegment], progress: Double) {
    barStack.arrangedSubviews.forEach { view in
      barStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    legendStack.arrangedSubviews.forEach { view in
      legendStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    let totalProportion = segments.reduce(0) { $0 + $1.proportion }
    if totalProportion > 0 {
      for segment in segments where segment.proportion > 0 {
        let fill = UIView()
        fill.backgroundColor = segment.color
        fill.layer.cornerRadius = 2
        fill.layer.cornerCurve = .continuous
        fill.translatesAutoresizingMaskIntoConstraints = false
        barStack.addArrangedSubview(fill)
        fill.heightAnchor.constraint(equalToConstant: 8).isActive = true
        fill.widthAnchor.constraint(
          equalTo: barStack.widthAnchor,
          multiplier: CGFloat(segment.proportion / totalProportion)
        ).isActive = true

        let legend = legendItem(name: segment.name, color: segment.color)
        legendStack.addArrangedSubview(legend)
      }
    } else {
      let track = UIView()
      track.backgroundColor = .tertiarySystemFill
      track.layer.cornerRadius = 2
      track.translatesAutoresizingMaskIntoConstraints = false
      barStack.addArrangedSubview(track)
      track.heightAnchor.constraint(equalToConstant: 8).isActive = true
      let fill = UIView()
      fill.backgroundColor = .systemBlue
      fill.layer.cornerRadius = 2
      fill.translatesAutoresizingMaskIntoConstraints = false
      track.addSubview(fill)
      NSLayoutConstraint.activate([
        fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
        fill.topAnchor.constraint(equalTo: track.topAnchor),
        fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
        fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: CGFloat(min(1, max(0, progress)))),
      ])
    }
  }

  private func commonInit() {
    let root = UIStackView(arrangedSubviews: [barStack, legendStack])
    root.axis = .vertical
    root.spacing = 8
    root.translatesAutoresizingMaskIntoConstraints = false

    barStack.axis = .horizontal
    barStack.spacing = 2
    barStack.distribution = .fill
    barStack.alignment = .fill

    legendStack.axis = .horizontal
    legendStack.spacing = 12
    legendStack.alignment = .center
    legendStack.distribution = .fillProportionally

    addSubview(root)
    NSLayoutConstraint.activate([
      root.topAnchor.constraint(equalTo: topAnchor),
      root.leadingAnchor.constraint(equalTo: leadingAnchor),
      root.trailingAnchor.constraint(equalTo: trailingAnchor),
      root.bottomAnchor.constraint(equalTo: bottomAnchor),
      barStack.heightAnchor.constraint(equalToConstant: 8),
    ])
  }

  private func legendItem(name: String, color: UIColor) -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 4
    row.alignment = .center

    let dot = UIView()
    dot.backgroundColor = color
    dot.layer.cornerRadius = 4
    dot.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      dot.widthAnchor.constraint(equalToConstant: 8),
      dot.heightAnchor.constraint(equalToConstant: 8),
    ])

    let label = UILabel()
    label.text = name
    label.font = .preferredFont(forTextStyle: .caption1)
    label.textColor = .secondaryLabel
    label.adjustsFontForContentSizeCategory = true

    row.addArrangedSubview(dot)
    row.addArrangedSubview(label)
    return row
  }
}
