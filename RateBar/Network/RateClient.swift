import Foundation

/// Fetches exchange-rate snapshots from a remote source.
protocol RateFetching: Sendable {
    func fetch(base: String, symbols: [String]) async throws -> RatesSnapshot
}

/// Errors produced by the exchange-rate HTTP client.
enum RateClientError: Error {
    case badStatus(Int)
    case decoding
    case transport(Error)
}

/// HTTP client for the exchangerate.host latest-rates endpoint.
struct ExchangeRateHostClient: RateFetching {
    private let endpoint: URL
    private let session: URLSession

    init(
        endpoint: URL = URL(string: "https://api.exchangerate.host/latest")!,
        session: URLSession = .shared
    ) {
        self.endpoint = endpoint
        self.session = session
    }

    /// Fetches a snapshot for the requested base currency and quote symbols.
    func fetch(base: String, symbols: [String]) async throws -> RatesSnapshot {
        let request = URLRequest(url: makeURL(base: base, symbols: symbols))
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

        do {
            return try JSONDecoder()
                .decode(ExchangeRateHostResponse.self, from: data)
                .toSnapshot()
        } catch {
            throw RateClientError.decoding
        }
    }

    private func makeURL(base: String, symbols: [String]) -> URL {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "base", value: base),
            URLQueryItem(name: "symbols", value: symbols.joined(separator: ",")),
        ]

        return components.url!
    }
}
