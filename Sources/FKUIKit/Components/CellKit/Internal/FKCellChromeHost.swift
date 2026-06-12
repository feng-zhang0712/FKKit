import UIKit

/// Common chrome surface shared by table and collection CellKit hosts.
@MainActor
protocol FKCellChromeHost: AnyObject {
  var isUserInteractionEnabled: Bool { get set }
  var backgroundColor: UIColor? { get set }
  var alpha: CGFloat { get set }
  var contentView: UIView { get }
}

extension UITableViewCell: FKCellChromeHost {}

extension UICollectionViewCell: FKCellChromeHost {}
