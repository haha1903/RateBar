@testable import RateBar
import XCTest

/// Tests for the open.er-api.com HTTP client and its error mapping.
final class RateClientTests: XCTestCase {
    private static let sampleJSON = """
    {
      "result": "success",
      "base_code": "AUD",
      "time_last_update_unix": 1777939351,
      "rates": {
        "CNY": 4.72,
        "USD": 0.65,
        "JPY": 101.34,
        "EUR": 0.59,
        "GBP": 0.51
      }
    }
    """

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testFetchSuccess() async throws {
        MockURLProtocol.setHandler { request in
            let data = try XCTUnwrap(Self.sampleJSON.data(using: .utf8))
            let response = try Self.makeResponse(statusCode: 200, url: request.url)
            return (response, data)
        }

        let snapshot = try await makeClient().fetch(
            base: "AUD",
            symbols: ["CNY", "USD", "JPY", "EUR"]
        )

        let requestURL = try XCTUnwrap(MockURLProtocol.lastRequest()?.url)
        let cnyRate = try XCTUnwrap(snapshot.rates["CNY"])

        XCTAssertEqual(requestURL.scheme, "https")
        XCTAssertEqual(requestURL.host, "open.er-api.com")
        XCTAssertEqual(requestURL.path, "/v6/latest/AUD")
        XCTAssertEqual(snapshot.base, "AUD")
        // GBP should be filtered out because it isn't in the requested symbols.
        XCTAssertEqual(snapshot.rates.count, 4)
        XCTAssertNil(snapshot.rates["GBP"])
        XCTAssertEqual(cnyRate, 4.72, accuracy: 0.000_001)
    }

    func testFetchKeepsAllRatesWhenSymbolsEmpty() async throws {
        MockURLProtocol.setHandler { request in
            let data = try XCTUnwrap(Self.sampleJSON.data(using: .utf8))
            let response = try Self.makeResponse(statusCode: 200, url: request.url)
            return (response, data)
        }

        let snapshot = try await makeClient().fetch(base: "AUD", symbols: [])

        XCTAssertEqual(snapshot.rates.count, 5)
    }

    func testFetchProviderFailure() async {
        MockURLProtocol.setHandler { request in
            let body = """
            {"result":"error","base_code":"AUD","rates":{}}
            """
            let data = try XCTUnwrap(body.data(using: .utf8))
            let response = try Self.makeResponse(statusCode: 200, url: request.url)
            return (response, data)
        }

        do {
            _ = try await makeClient().fetch(base: "AUD", symbols: ["CNY"])
            XCTFail("Expected providerFailure error")
        } catch RateClientError.providerFailure(let result) {
            XCTAssertEqual(result, "error")
        } catch {
            XCTFail("Expected providerFailure error, got \(error)")
        }
    }

    func testFetchHTTP500() async {
        MockURLProtocol.setHandler { request in
            let response = try Self.makeResponse(statusCode: 500, url: request.url)
            return (response, Data())
        }

        do {
            _ = try await makeClient().fetch(base: "AUD", symbols: ["CNY"])
            XCTFail("Expected badStatus error")
        } catch RateClientError.badStatus(let statusCode) {
            XCTAssertEqual(statusCode, 500)
        } catch {
            XCTFail("Expected badStatus error, got \(error)")
        }
    }

    func testFetchBadJSON() async {
        MockURLProtocol.setHandler { request in
            let data = try XCTUnwrap("not json".data(using: .utf8))
            let response = try Self.makeResponse(statusCode: 200, url: request.url)
            return (response, data)
        }

        do {
            _ = try await makeClient().fetch(base: "AUD", symbols: ["CNY"])
            XCTFail("Expected decoding error")
        } catch RateClientError.decoding {
            // Expected path.
        } catch {
            XCTFail("Expected decoding error, got \(error)")
        }
    }

    private func makeClient() -> OpenERAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]

        return OpenERAPIClient(session: URLSession(configuration: configuration))
    }

    private static func makeResponse(statusCode: Int, url: URL?) throws -> HTTPURLResponse {
        let url = try XCTUnwrap(url)
        return try XCTUnwrap(
            HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
        )
    }
}

private final class MockURLProtocolState: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    private var request: URLRequest?

    func setHandler(_ handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    func reset() {
        lock.lock()
        handler = nil
        request = nil
        lock.unlock()
    }

    func record(_ request: URLRequest) {
        lock.lock()
        self.request = request
        lock.unlock()
    }

    func lastRequest() -> URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return request
    }

    func currentHandler() -> ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        lock.lock()
        defer { lock.unlock() }
        return handler
    }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    private static let state = MockURLProtocolState()

    static func setHandler(_ handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)) {
        state.setHandler(handler)
    }

    static func reset() {
        state.reset()
    }

    static func lastRequest() -> URLRequest? {
        state.lastRequest()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.state.currentHandler() else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            Self.state.record(request)
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
