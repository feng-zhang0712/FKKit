import UIKit

@MainActor
protocol FKPresentationHosting: AnyObject {
  var isPresented: Bool { get }
  func present(from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?)
  func dismiss(animated: Bool, completion: (() -> Void)?)
  func updateLayout()
}

