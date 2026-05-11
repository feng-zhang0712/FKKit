import UIKit
import FKCoreKit

/// Interactive demo of **all** public `FKAsync` APIs. Each section maps to one API family; button titles name the symbol under test.
///
/// Coverage: `FKAsync` (main/background/serial & concurrent batches/coordination queue), `FKAsyncQueues`, `FKAsyncTaskGroup`,
/// `FKDebouncer`, `FKThrottler`, `FKCancellableDelayedWork`, executors, `DispatchQueue` extensions, thread checks.
final class FKAsyncExampleViewController: UIViewController, UISearchBarDelegate, UIScrollViewDelegate {
  // MARK: - FKAsync components

  private let async = FKAsync.shared

  /// Separate hub to demonstrate a custom `coordinationQueueLabel` (isolated from `shared`'s default queue).
  private let asyncIsolated = FKAsync(coordinationQueueLabel: "com.fkkit.examples.async.isolated")

  private let searchDebouncer = FKDebouncer(interval: 0.35, queue: .main)
  private let eventThrottler = FKThrottler(interval: 0.5, queue: .main)
  private let delayedWork = FKCancellableDelayedWork(queue: .main)

  private let serialExecutor = FKAsyncSerialExecutor(label: "com.fkkit.examples.async.serial")
  private let concurrentExecutor = FKAsyncConcurrentExecutor(label: "com.fkkit.examples.async.concurrent")

  /// Private serial queue for `fk_async` / `fk_asyncAfter` demos.
  private let extensionDemoQueue = FKAsyncQueues.serial(label: "com.fkkit.examples.async.dispatch-extension")

  // MARK: - UI

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let searchBar = UISearchBar()
  private let throttleTapButton = UIButton(type: .system)
  private let demoScrollView = UIScrollView()
  private let logView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKAsync"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendLog("Loaded. Tap buttons top to bottom; the log explains each API and which thread runs the closure.")
  }

  deinit {
    delayedWork.cancel()
    searchDebouncer.cancelPending()
  }

  // MARK: - Layout

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 6

    searchBar.placeholder = "Debouncer: type continuously; fires once after 0.35s idle"
    searchBar.delegate = self

    throttleTapButton.setTitle("Throttler: rapid taps (first fire per 0.5s window)", for: .normal)
    throttleTapButton.contentHorizontalAlignment = .left
    throttleTapButton.addTarget(self, action: #selector(runThrottleButtonDemo), for: .touchUpInside)

    configureThrottleScrollDemo()

    let sections: [(title: String, actions: [(String, Selector)])] = [
      (
        "1. Main thread: runOnMain / asyncOnMain / asyncMainDeferred",
        [
          ("runOnMain: sleep 0.15s off main, then hop to main for UI", #selector(demoRunOnMainFromBackground)),
          ("asyncOnMain: always async to main (next run loop turn)", #selector(demoAsyncOnMain)),
          ("asyncMainDeferred: same semantics as asyncOnMain (alias)", #selector(demoAsyncMainDeferred)),
          ("Ordering: runOnMain vs asyncOnMain when invoked on main", #selector(demoMainThreadOrdering)),
        ]
      ),
      (
        "2. DispatchQueue extensions: fk_runOnMain / fk_asyncOnMain / fk_async / fk_asyncAfter",
        [
          ("DispatchQueue.fk_runOnMain { … }", #selector(demoFkRunOnMain)),
          ("DispatchQueue.fk_asyncOnMain { … }", #selector(demoFkAsyncOnMain)),
          ("Custom serial queue: .fk_async / .fk_asyncAfter(0.5s)", #selector(demoFkAsyncExtensionsOnSerialQueue)),
        ]
      ),
      (
        "3. Background: asyncBackground / asyncGlobal",
        [
          ("asyncBackground (global .default QoS)", #selector(demoAsyncBackground)),
          ("asyncGlobal(qos: .userInitiated) + runOnMain for result", #selector(demoAsyncGlobalUserInitiated)),
        ]
      ),
      (
        "4. FKCancellableDelayedWork: schedule / cancel",
        [
          ("schedule(after: 2s) single-shot delay", #selector(scheduleDelayTask)),
          ("cancel() pending work item", #selector(cancelDelayTask)),
        ]
      ),
      (
        "5. FKDebouncer: signal / cancelPending",
        [
          ("cancelPending() clears the pending debounced fire", #selector(demoDebouncerCancelPending)),
        ]
      ),
      (
        "6. FKThrottler: throttle / reset",
        [
          ("reset() clears last-invocation; next throttle can fire immediately", #selector(demoThrottlerReset)),
        ]
      ),
      (
        "7. FKAsyncTaskGroup: enter+leave / enterAndAsync / notify",
        [
          ("Manual enter → asyncGlobal → leave (3 tasks)", #selector(demoDispatchGroupManual)),
          ("enterAndAsync(on:execute:) recommended pattern", #selector(demoTaskGroupEnterAndAsync)),
        ]
      ),
      (
        "8. Batches: runSerial / runSerialOnCoordinationQueue / runConcurrent",
        [
          ("runSerial(on: custom serial queue)", #selector(demoRunSerialCustomQueue)),
          ("runSerialOnCoordinationQueue (FKAsync.shared coordination queue)", #selector(demoRunSerialOnCoordinationQueue)),
          ("runConcurrent (parallel ops + one completion)", #selector(demoRunConcurrent)),
        ]
      ),
      (
        "9. FKAsyncQueues: global / serial / concurrent",
        [
          ("global + concurrent: one log line each", #selector(demoFKAsyncQueuesFactories)),
        ]
      ),
      (
        "10. Executors: FKAsyncSerialExecutor / FKAsyncConcurrentExecutor + asyncAfter",
        [
          ("SerialExecutor: two async + asyncAfter", #selector(demoSerialExecutor)),
          ("ConcurrentExecutor: two async + asyncAfter", #selector(demoConcurrentExecutor)),
        ]
      ),
      (
        "11. Thread checks & misc",
        [
          ("FKAsync.isMainThread / currentIsMainThread()", #selector(demoCheckThread)),
          ("Configuration.default… + underlyingCoordinationQueue", #selector(demoUnderlyingCoordinationLabel)),
          ("Clear log", #selector(clearLogs)),
        ]
      ),
    ]

    for section in sections {
      stackView.addArrangedSubview(makeSectionTitle(section.title))
      for row in section.actions {
        stackView.addArrangedSubview(makeDemoButton(title: row.0, action: row.1))
      }
      stackView.setCustomSpacing(14, after: stackView.arrangedSubviews.last!)
    }

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.layer.cornerRadius = 8
    logView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(logView)

    stackView.addArrangedSubview(makeSectionTitle("Debouncer (UISearchBar)"))
    stackView.addArrangedSubview(searchBar)
    stackView.addArrangedSubview(makeSectionTitle("Throttler (button + scroll view below)"))
    stackView.addArrangedSubview(throttleTapButton)
    stackView.addArrangedSubview(demoScrollView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.52),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      logView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func makeSectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.accessibilityTraits.insert(.header)
    return label
  }

  private func makeDemoButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.textAlignment = .left
    button.contentHorizontalAlignment = .leading
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  private func configureThrottleScrollDemo() {
    demoScrollView.delegate = self
    demoScrollView.backgroundColor = .secondarySystemBackground
    demoScrollView.layer.cornerRadius = 8
    demoScrollView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    let content = UIView()
    content.translatesAutoresizingMaskIntoConstraints = false
    content.backgroundColor = .clear
    demoScrollView.addSubview(content)
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: demoScrollView.contentLayoutGuide.topAnchor),
      content.leadingAnchor.constraint(equalTo: demoScrollView.contentLayoutGuide.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: demoScrollView.contentLayoutGuide.trailingAnchor),
      content.bottomAnchor.constraint(equalTo: demoScrollView.contentLayoutGuide.bottomAnchor),
      content.widthAnchor.constraint(equalTo: demoScrollView.frameLayoutGuide.widthAnchor),
      content.heightAnchor.constraint(equalToConstant: 500),
    ])
    for i in 0..<8 {
      let row = UIView()
      row.translatesAutoresizingMaskIntoConstraints = false
      row.backgroundColor = i % 2 == 0 ? .systemBlue.withAlphaComponent(0.15) : .systemGreen.withAlphaComponent(0.15)
      row.layer.cornerRadius = 6
      content.addSubview(row)
      NSLayoutConstraint.activate([
        row.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
        row.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
        row.heightAnchor.constraint(equalToConstant: 48),
        row.topAnchor.constraint(equalTo: content.topAnchor, constant: CGFloat(12 + i * 60)),
      ])
    }
  }

  // MARK: - 1) Main-thread APIs

  @objc private func demoRunOnMainFromBackground() {
    appendLog("[runOnMain] Start on asyncBackground, sleep, then update UI on main.")
    async.asyncBackground { [weak self] in
      Thread.sleep(forTimeInterval: 0.15)
      self?.async.runOnMain { [weak self] in
        self?.appendLog("  -> runOnMain closure: Thread.isMainThread=\(Thread.isMainThread)")
      }
    }
  }

  @objc private func demoAsyncOnMain() {
    appendLog("[asyncOnMain] Even on main, work is **queued** for the next main run-loop turn (not inline).")
    async.asyncOnMain { [weak self] in
      self?.appendLog("  -> asyncOnMain fired, isMain=\(Thread.isMainThread)")
    }
    appendLog("  (This line is synchronous right after scheduling asyncOnMain, so it typically prints before the async closure.)")
  }

  @objc private func demoAsyncMainDeferred() {
    appendLog("[asyncMainDeferred] Same implementation as asyncOnMain; name reads as \"defer to next main turn\".")
    async.asyncMainDeferred { [weak self] in
      self?.appendLog("  -> asyncMainDeferred fired, isMain=\(Thread.isMainThread)")
    }
  }

  @objc private func demoMainThreadOrdering() {
    appendLog("[Ordering] Invoked from the **main** thread via this button:")
    appendLog("  (1) synchronous log")
    async.runOnMain { [weak self] in
      self?.appendLog("  (2) runOnMain: on main, runs **synchronously**")
    }
    appendLog("  (3) after runOnMain returns (should follow (2) immediately)")
    async.asyncOnMain { [weak self] in
      self?.appendLog("  (4) asyncOnMain: always next main-queue turn, so after (3)")
    }
    appendLog("  (5) end of action method (usually before (4))")
  }

  // MARK: - 2) DispatchQueue extensions

  @objc private func demoFkRunOnMain() {
    appendLog("[DispatchQueue.fk_runOnMain] Same strategy as FKAsync.runOnMain: sync on main, else async to main.")
    DispatchQueue.fk_runOnMain { [weak self] in
      self?.appendLog("  -> fk_runOnMain closure isMain=\(Thread.isMainThread)")
    }
  }

  @objc private func demoFkAsyncOnMain() {
    appendLog("[DispatchQueue.fk_asyncOnMain] Equivalent to DispatchQueue.main.async.")
    DispatchQueue.fk_asyncOnMain { [weak self] in
      self?.appendLog("  -> fk_asyncOnMain closure isMain=\(Thread.isMainThread)")
    }
  }

  @objc private func demoFkAsyncExtensionsOnSerialQueue() {
    appendLog("[fk_async / fk_asyncAfter] On extensionDemoQueue: immediate block, then delayed 0.5s.")
    extensionDemoQueue.fk_async { [weak self] in
      self?.appendLog("  -> fk_async ran (isMain=\(Thread.isMainThread))")
    }
    extensionDemoQueue.fk_asyncAfter(delay: 0.5) { [weak self] in
      self?.appendLog("  -> fk_asyncAfter(0.5s) ran (isMain=\(Thread.isMainThread))")
    }
  }

  // MARK: - 3) Background

  @objc private func demoAsyncBackground() {
    appendLog("[asyncBackground] Uses global concurrent queue with .default QoS.")
    async.asyncBackground { [weak self] in
      let n = (1...10_000).reduce(0, +)
      self?.async.runOnMain { [weak self] in
        self?.appendLog("  -> background sum=\(n), back on main.")
      }
    }
  }

  @objc private func demoAsyncGlobalUserInitiated() {
    appendLog("[asyncGlobal(qos: .userInitiated)] Explicit QoS for user-initiated heavy work.")
    async.asyncGlobal(qos: .userInitiated) { [weak self] in
      let sum = (1...50_000).reduce(0, +)
      self?.async.runOnMain { [weak self] in
        self?.appendLog("  -> result=\(sum)")
      }
    }
  }

  // MARK: - 4) Cancellable delay

  @objc private func scheduleDelayTask() {
    appendLog("[FKCancellableDelayedWork.schedule(after: 2)] Fires in 2s unless cancel() runs first.")
    delayedWork.schedule(after: 2.0) { [weak self] in
      self?.appendLog("  -> delayed work **fired** (not cancelled)")
    }
  }

  @objc private func cancelDelayTask() {
    delayedWork.cancel()
    appendLog("[cancel] Pending DispatchWorkItem cancelled.")
  }

  // MARK: - 5) Debouncer

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchDebouncer.signal { [weak self] in
      self?.appendLog("[Debouncer.signal] Idle window elapsed: \"\(searchText)\"")
    }
  }

  @objc private func demoDebouncerCancelPending() {
    searchDebouncer.cancelPending()
    appendLog("[Debouncer.cancelPending] Cleared pending work; typing in the search bar starts a fresh timer.")
  }

  // MARK: - 6) Throttler

  @objc private func runThrottleButtonDemo() {
    appendLog("[Throttler.throttle] Button: multiple taps in 0.5s map to at most one scheduled execution.")
    eventThrottler.throttle { [weak self] in
      self?.appendLog("  -> throttle closure ran (isMain=\(Thread.isMainThread))")
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView === demoScrollView else { return }
    let offset = Int(scrollView.contentOffset.y)
    eventThrottler.throttle { [weak self] in
      self?.appendLog("[Throttler + scroll] y=\(offset)")
    }
  }

  @objc private func demoThrottlerReset() {
    eventThrottler.reset()
    appendLog("[Throttler.reset] Cleared lastInvocation; next throttle can pass immediately.")
  }

  // MARK: - 7) TaskGroup

  @objc private func demoDispatchGroupManual() {
    appendLog("[FKAsyncTaskGroup] Manual enter/leave: three background tasks with different sleeps.")
    let group = FKAsyncTaskGroup()
    for idx in 1...3 {
      group.enter()
      async.asyncGlobal(qos: .utility) {
        Thread.sleep(forTimeInterval: 0.2 * Double(idx))
        group.leave()
      }
    }
    group.notify(queue: .main) { [weak self] in
      self?.appendLog("  -> notify: all leave() calls done")
    }
  }

  @objc private func demoTaskGroupEnterAndAsync() {
    appendLog("[enterAndAsync] enter + queue.async + defer leave avoids missing leave().")
    let group = FKAsyncTaskGroup()
    let bg = FKAsyncQueues.global(qos: .utility)
    for idx in 1...3 {
      group.enterAndAsync(on: bg) { [weak self] in
        Thread.sleep(forTimeInterval: 0.12 * Double(idx))
        self?.appendLog("  -> child task \(idx) finished (isMain=\(Thread.isMainThread))")
      }
    }
    group.notify(queue: .main) { [weak self] in
      self?.appendLog("  -> notify: enterAndAsync batch complete")
    }
  }

  // MARK: - 8) Serial & concurrent batches

  @objc private func demoRunSerialCustomQueue() {
    appendLog("[runSerial] Runs A->B->C on a **custom** serial queue; completion on main.")
    async.runSerial(
      [
        { [weak self] in self?.appendLog("  (1) Serial A") },
        { [weak self] in self?.appendLog("  (2) Serial B") },
        { [weak self] in self?.appendLog("  (3) Serial C") },
      ],
      on: FKAsyncQueues.serial(label: "com.fkkit.examples.async.serial.demo"),
      notifyQueue: .main
    ) { [weak self] in
      self?.appendLog("  -> runSerial completion")
    }
  }

  @objc private func demoRunSerialOnCoordinationQueue() {
    appendLog("[runSerialOnCoordinationQueue] Uses `FKAsync.shared`'s private coordination serial queue (not the global pool).")
    async.runSerialOnCoordinationQueue(
      [
        { [weak self] in self?.appendLog("  (1) coord-1") },
        { [weak self] in self?.appendLog("  (2) coord-2") },
      ],
      notifyQueue: .main
    ) { [weak self] in
      self?.appendLog("  -> coordination serial batch complete")
    }
  }

  @objc private func demoRunConcurrent() {
    appendLog("[runConcurrent] Closures run in parallel on a global concurrent queue; one completion when all finish.")
    async.runConcurrent(
      [
        { [weak self] in self?.appendLog("  || Task A start"); Thread.sleep(forTimeInterval: 0.08); self?.appendLog("  || Task A end") },
        { [weak self] in self?.appendLog("  || Task B start"); Thread.sleep(forTimeInterval: 0.12); self?.appendLog("  || Task B end") },
        { [weak self] in self?.appendLog("  || Task C start"); Thread.sleep(forTimeInterval: 0.06); self?.appendLog("  || Task C end") },
      ],
      qos: .userInitiated,
      notifyQueue: .main
    ) { [weak self] in
      self?.appendLog("  -> runConcurrent completion")
    }
  }

  // MARK: - 9) FKAsyncQueues

  @objc private func demoFKAsyncQueuesFactories() {
    appendLog("[FKAsyncQueues] global + concurrent factories each enqueue one log line.")
    FKAsyncQueues.global(qos: .utility).async { [weak self] in
      self?.appendLog("  -> global(.utility) closure isMain=\(Thread.isMainThread)")
    }
    let cq = FKAsyncQueues.concurrent(label: "com.fkkit.examples.async.queues.concurrent", qos: .default)
    cq.async { [weak self] in
      self?.appendLog("  -> concurrent queue closure isMain=\(Thread.isMainThread)")
    }
  }

  // MARK: - 10) Executors

  @objc private func demoSerialExecutor() {
    appendLog("[FKAsyncSerialExecutor] Order: immediate #1 -> immediate #2 -> asyncAfter +0.25s #3")
    serialExecutor.async { [weak self] in
      self?.appendLog("  -> Serial #1")
    }
    serialExecutor.async { [weak self] in
      self?.appendLog("  -> Serial #2")
    }
    serialExecutor.asyncAfter(deadline: .now() + 0.25) { [weak self] in
      self?.appendLog("  -> Serial #3 (asyncAfter)")
    }
  }

  @objc private func demoConcurrentExecutor() {
    appendLog("[FKAsyncConcurrentExecutor] Two async blocks may finish out of order; asyncAfter follows.")
    concurrentExecutor.async { [weak self] in
      Thread.sleep(forTimeInterval: 0.06)
      self?.appendLog("  -> Concurrent slow")
    }
    concurrentExecutor.async { [weak self] in
      self?.appendLog("  -> Concurrent fast")
    }
    concurrentExecutor.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      self?.appendLog("  -> Concurrent asyncAfter")
    }
  }

  // MARK: - 11) Thread checks & misc

  @objc private func demoCheckThread() {
    appendLog("[Thread] FKAsync.isMainThread=\(FKAsync.isMainThread)")
    async.asyncBackground { [weak self] in
      self?.appendLog("[Thread] On background: FKAsync.currentIsMainThread()=\(FKAsync.currentIsMainThread())")
    }
  }

  @objc private func demoUnderlyingCoordinationLabel() {
    appendLog("[FKAsync.Configuration] defaultCoordinationQueueLabel=\"\(FKAsync.Configuration.defaultCoordinationQueueLabel)\"")
    let label = async.underlyingCoordinationQueue.label
    appendLog("[FKAsync.underlyingCoordinationQueue] shared label=\"\(label)\"")
    let isolated = asyncIsolated.underlyingCoordinationQueue.label
    appendLog("[Isolated FKAsync] asyncIsolated label=\"\(isolated)\" (distinct from shared)")
  }

  @objc private func clearLogs() {
    Task { @MainActor [weak self] in
      self?.logView.text = ""
    }
  }

  // MARK: - Logging (callable from any thread)

  private nonisolated func appendLog(_ message: String) {
    Task { @MainActor [weak self] in
      self?.appendLogOnMain(message)
    }
  }

  @MainActor
  private func appendLogOnMain(_ message: String) {
    let prefix = DateFormatter.fkAsyncLogFormatter.string(from: Date())
    let line = "[\(prefix)] \(message)\n"
    logView.text.append(line)
    let range = NSRange(location: max(logView.text.count - 1, 0), length: 1)
    logView.scrollRangeToVisible(range)
  }
}

private extension DateFormatter {
  static let fkAsyncLogFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()
}
