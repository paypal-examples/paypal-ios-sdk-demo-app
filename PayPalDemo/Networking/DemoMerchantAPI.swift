import Foundation
import CorePayments

/// API Client used to create and process orders on sample merchant server
final class DemoCartAPI {

    static let shared = DemoCartAPI()
    
    // Maps order tokens to cart IDs for completion
    private var tokenToCartIDMap: [String: String] = [:]

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
        // Get access token
        let accessToken = try await getAccessToken()
        
        // Create cart params
        let cartParams = CreateCartParams(
            items: [
                CreateCartParams.CartItem(itemId: "test-item-id-from-paypal", quantity: 1)
            ],
            customer: CreateCartParams.Customer(
                name: CreateCartParams.Customer.Name(givenName: "John", surname: "Doe"),
                emailAddress: "test@example.com",
                phone: CreateCartParams.Customer.Phone(countryCode: "1", nationalNumber: "2223334444")
            ),
            paymentMethod: CreateCartParams.PaymentMethod(
                paypal: CreateCartParams.PaymentMethod.PayPalMethod(
                    experienceContext: CreateCartParams.PaymentMethod.PayPalMethod.ExperienceContext(
                        returnUrl: "https://www.example.com/return",
                        cancelUrl: "https://www.example.com/cancel",
                        shippingAddressPreference: "CHANGE_ALLOWED"
                    )
                )
            )
        )
        
        // Make request to carts endpoint
        guard let url = buildPayPalURL(with: "/v1/commerce/carts") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = buildURLRequest(method: "POST", url: url, body: cartParams)
        urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let data = try await data(for: urlRequest)
        let cartResponse: CartResponse = try parse(from: data)
        
        // Extract order token from payer-action link
        guard let orderToken = cartResponse.extractOrderToken() else {
            throw APIError.dataParsingError
        }
        
        // Store mapping of token to cart ID for later completion
        tokenToCartIDMap[orderToken] = cartResponse.id
        
        // Return Order with token as id (for SDK compatibility)
        return Order(id: orderToken, status: cartResponse.status)
    }
    
    private func getAccessToken() async throws -> String {
        let clientID = "AQTfw2irFfemo-eWG4H5UY-b9auKihUpXQ2Engl4G1EsHJe2mkpfUv_SN3Mba0v3CfrL6Fk_ecwv9EOo"
        let secret = "YOUR_CLIENT_SECRET" // You'll need to provide the actual secret
        
        guard let url = buildPayPalURL(with: "/v1/oauth2/token") else {
            throw APIError.invalidURL
        }
        
        let credentials = "\(clientID):\(secret)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw APIError.unknown
        }
        let base64Credentials = credentialsData.base64EncodedString()
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = "grant_type=client_credentials".data(using: .utf8)
        
        let data = try await data(for: urlRequest)
        
        struct TokenResponse: Codable {
            let accessToken: String
            
            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
            }
        }
        
        let tokenResponse: TokenResponse = try parse(from: data)
        return tokenResponse.accessToken
    }

    func completeOrder(
        orderID: String,
        payPalClientMetadataID: String? = nil,
        intent: Intent
    ) async throws -> Order {
        // Get access token
        let accessToken = try await getAccessToken()
        
        // Get the cart ID from the token mapping
        guard let cartID = tokenToCartIDMap[orderID] else {
            throw APIError.dataParsingError
        }
        
        guard let url = buildPayPalURL(with: "/v1/commerce/carts/\(cartID)/complete") else {
            throw APIError.invalidURL
        }

        var urlRequest = buildURLRequest(method: "POST", url: url, body: EmptyBodyParams())
        urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        if let payPalClientMetadataID {
            urlRequest.addValue(payPalClientMetadataID, forHTTPHeaderField: "PayPal-Client-Metadata-Id")
        }
        let data = try await data(for: urlRequest)
        
        // Clean up the mapping after completion
        tokenToCartIDMap.removeValue(forKey: orderID)
        
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
