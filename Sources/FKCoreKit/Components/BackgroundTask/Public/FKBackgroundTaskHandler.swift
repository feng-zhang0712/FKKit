import Foundation

/// Handler invoked when the system launches a registered background task.
public typealias FKBackgroundTaskHandler = @Sendable (FKBackgroundTaskHandle) async -> Bool
