#if os(iOS)
import Foundation
@preconcurrency import BackgroundTasks

enum FKBackgroundTaskMapper {
  static func makeAppRefreshRequest(from request: FKBackgroundAppRefreshRequest) -> BGAppRefreshTaskRequest {
    let bgRequest = BGAppRefreshTaskRequest(identifier: request.identifier)
    bgRequest.earliestBeginDate = request.earliestBeginDate
    return bgRequest
  }

  static func makeProcessingRequest(from request: FKBackgroundProcessingRequest) -> BGProcessingTaskRequest {
    let bgRequest = BGProcessingTaskRequest(identifier: request.identifier)
    bgRequest.earliestBeginDate = request.earliestBeginDate
    bgRequest.requiresNetworkConnectivity = request.requiresNetworkConnectivity
    bgRequest.requiresExternalPower = request.requiresExternalPower
    return bgRequest
  }

  static func makePendingSummary(from request: BGTaskRequest) -> FKBackgroundTaskPendingSummary {
    if let refresh = request as? BGAppRefreshTaskRequest {
      return FKBackgroundTaskPendingSummary(
        identifier: refresh.identifier,
        kind: .appRefresh,
        earliestBeginDate: refresh.earliestBeginDate
      )
    }

    if let processing = request as? BGProcessingTaskRequest {
      return FKBackgroundTaskPendingSummary(
        identifier: processing.identifier,
        kind: .processing,
        earliestBeginDate: processing.earliestBeginDate,
        requiresNetworkConnectivity: processing.requiresNetworkConnectivity,
        requiresExternalPower: processing.requiresExternalPower
      )
    }

    return FKBackgroundTaskPendingSummary(
      identifier: request.identifier,
      kind: .appRefresh,
      earliestBeginDate: request.earliestBeginDate
    )
  }
}

#endif
