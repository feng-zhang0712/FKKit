/// Controls when ``FKDefaultRefreshContentView`` shows status text beside the indicator.
public enum FKRefreshStatusTextMode: Sendable {
  /// Arrow/spinner plus copy for every applicable state (default).
  case full
  /// Indicator only — no status label. VoiceOver still uses bundled FKUIKit strings.
  case indicatorOnly
}

/// Footer behavior after ``FKRefreshState/noMoreData`` is reached.
public enum FKRefreshNoMoreDataBehavior: Sendable {
  /// Keep the footer visible (shows bundled no-more copy when ``FKRefreshStatusTextMode/full``).
  case showFooter
  /// Hide the load-more control after the hold duration (common in infinite-feed apps).
  case hideFooter
}
