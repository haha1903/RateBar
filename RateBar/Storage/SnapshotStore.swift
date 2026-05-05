import Foundation

/// Persists the latest exchange-rate snapshot in a UserDefaults-backed cache.
struct SnapshotStore {
    static let defaultKey = "rateSnapshot"

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = Self.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    /// Saves a snapshot as JSON so the app can restore the last successful refresh.
    func save(_ snapshot: RatesSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: key)
    }

    /// Loads the cached snapshot, returning nil when no valid cache exists.
    func load() -> RatesSnapshot? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(RatesSnapshot.self, from: data)
    }
}
