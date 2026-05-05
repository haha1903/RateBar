import Foundation

/// Coordinates startup and recurring refreshes for the exchange-rate service.
@MainActor
final class RefreshScheduler {
    private let service: RateService
    private let intervalNanoseconds: UInt64
    private var refreshLoopTask: Task<Void, Never>?

    init(service: RateService, interval: TimeInterval = 3_600) {
        self.service = service
        self.intervalNanoseconds = Self.nanoseconds(for: interval)
    }

    /// Starts a refresh loop, immediately refreshing once before waiting for the interval.
    func start() {
        stop()

        refreshLoopTask = Task { @MainActor [service, intervalNanoseconds] in
            await service.refresh()

            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: intervalNanoseconds)
                } catch {
                    break
                }

                guard !Task.isCancelled else {
                    break
                }

                await service.refresh()
            }
        }
    }

    /// Cancels any scheduled future refreshes.
    func stop() {
        refreshLoopTask?.cancel()
        refreshLoopTask = nil
    }

    private static func nanoseconds(for interval: TimeInterval) -> UInt64 {
        let minimumInterval = 0.001
        let clampedInterval = max(interval, minimumInterval)
        return UInt64((clampedInterval * 1_000_000_000).rounded())
    }
}
