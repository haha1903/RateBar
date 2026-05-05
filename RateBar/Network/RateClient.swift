import Foundation

/// Fetches exchange-rate snapshots from a remote source.
protocol RateFetching: Sendable {
    func fetch(base: String, symbols: [String]) async throws -> RatesSnapshot
}

/// Errors produced by the exchange-rate HTTP client.
enum RateClientError: Error {
    case badStatus(Int)
    case decoding
    case providerFailure(String)
    case transport(Error)
}

/// HTTP client for the open.er-api.com latest-rates endpoint.
///
/// The endpoint returns rates for all supported quote currencies in a single
/// response keyed off the base currency in the URL path
/// (e.g. `https://open.er-api.com/v6/latest/AUD`). The optional `symbols`
/// argument is filtered client-side because the provider does not support a
/// server-side projection.
struct OpenERAPIClient: RateFetching {
    private let endpoint: URL
    private let session: URLSession

    init(
        endpoint: URL = URL(string: "https://open.er-api.com/v6/latest")!,
        session: URLSession = .shared
    ) {
        self.endpoint = endpoint
        self.session = session
    }

    /// Fetches a snapshot for the requested base currency and quote symbols.
    /// `symbols` is used to filter the returned snapshot client-side; pass an
    /// empty array to keep all rates returned by the provider.
    func fetch(base: String, symbols: [String]) async throws -> RatesSnapshot {
        let request = URLRequest(url: makeURL(base: base))
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw RateClientError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RateClientError.transport(URLError(.badServerResponse))
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw RateClientError.badStatus(httpResponse.statusCode)
        }

        let decoded: OpenERAPIResponse
        do {
            decoded = try JSONDecoder().decode(OpenERAPIResponse.self, from: data)
        } catch {
            throw RateClientError.decoding
        }

        guard decoded.result == "success" else {
            throw RateClientError.providerFailure(decoded.result)
        }

        let snapshot = decoded.toSnapshot()
        guard !symbols.isEmpty else { return snapshot }

        let wanted = Set(symbols)
        let filtered = snapshot.rates.filter { wanted.contains($0.key) }
        return RatesSnapshot(
            base: snapshot.base,
            fetchedAt: snapshot.fetchedAt,
            rates: filtered
        )
    }

    private func makeURL(base: String) -> URL {
        endpoint.appendingPathComponent(base.uppercased())
    }
}
