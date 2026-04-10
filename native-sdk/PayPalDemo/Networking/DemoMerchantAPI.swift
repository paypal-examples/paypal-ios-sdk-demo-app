import Foundation
import CorePayments

/// API Client used to create and process orders on sample merchant server
final class DemoMerchantAPI {

    static let shared = DemoMerchantAPI()

    private init() {}

    public func getCoreConfig() async throws -> CoreConfig {
        let clientID = "AQTfw2irFfemo-eWG4H5UY-b9auKihUpXQ2Engl4G1EsHJe2mkpfUv_SN3Mba0v3CfrL6Fk_ecwv9EOo"
        return CoreConfig(clientID: clientID, environment: DemoSettings.environment.paypalSDKEnvironment)
    }

    /// This function replicates a way a merchant may go about creating an order on their server and is not part of the SDK flow.
    /// - Parameter orderParams: the parameters to create the order with
    /// - Returns: an order
    /// - Throws: an error explaining why create order failed
    func createOrder(orderParams: CreateOrderParams) async throws -> Order {
        guard let url = buildBaseURL(with: "/orders") else {
            throw APIError.invalidURL
        }

        let urlRequest = buildURLRequest(method: "POST", url: url, body: orderParams)
        let data = try await data(for: urlRequest)
        return try parse(from: data)
    }

    func completeOrder(
        orderID: String,
        payPalClientMetadataID: String? = nil,
        intent: Intent
    ) async throws -> Order {
        guard let url = buildBaseURL(with: "/orders/\(orderID)/\(intent.rawValue)") else {
            throw APIError.invalidURL
        }

        var urlRequest = buildURLRequest(method: "POST", url: url, body: EmptyBodyParams())
        if let payPalClientMetadataID {
            urlRequest.addValue(payPalClientMetadataID, forHTTPHeaderField: "PayPal-Client-Metadata-Id")
        }
        let data = try await data(for: urlRequest)
        return try parse(from: data)
    }

    // MARK: Private methods

    private func buildBaseURL(with endpoint: String) -> URL? {
        return URL(string: DemoSettings.environment.baseURL + endpoint)
    }

    private func buildPayPalURL(with endpoint: String) -> URL? {
        URL(string: "https://api.sandbox.paypal.com" + endpoint)
    }

    private func buildURLRequest<T>(method: String, url: URL, body: T?) -> URLRequest where T: Encodable {
        let encoder = JSONEncoder()
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if method != "GET", let json = try? encoder.encode(body) {
            print(String(data: json, encoding: .utf8) ?? "")
                urlRequest.httpBody = json
        }

        return urlRequest
    }

    private func data(for urlRequest: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.httpResponseError
            }

            switch httpResponse.statusCode {
            case 200..<300:
                return data
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unknown
        }
    }

    private func parse<T: Decodable>(from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.dataParsingError
        }
    }
}
