import PhotosUI
import UIKit

@MainActor
final class FKPHPickerDelegateAdapter: NSObject, PHPickerViewControllerDelegate {
  private let completion: ([PHPickerResult]) -> Void

  init(completion: @escaping ([PHPickerResult]) -> Void) {
    self.completion = completion
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    completion(results)
  }
}

@MainActor
final class FKImagePickerDelegateAdapter: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private let completion: (Result<[UIImagePickerController.InfoKey: Any], FKPhotoPickerError>) -> Void

  init(completion: @escaping (Result<[UIImagePickerController.InfoKey: Any], FKPhotoPickerError>) -> Void) {
    self.completion = completion
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    completion(.failure(.cancelled))
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    completion(.success(info))
  }
}
