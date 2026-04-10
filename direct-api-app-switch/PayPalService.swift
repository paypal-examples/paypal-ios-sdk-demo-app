// PayPalService.swift
// Handles all PayPal Direct API calls using URLSession (no dependencies).
//
// WARNING: Client ID and Secret are hardcoded for sandbox testing only.
// In production, ALL API calls must go through your server -- never expose
// credentials in a shipping app.

import Foundation

class PayPalService {
    static let shared = PayPalService()

    // -- Configuration (loaded from Config.plist) --
    private let apiBase = "https://api-m.sandbox.paypal.com"
    private let clientId: String
    private let clientSecret: String
    private let returnDomain: String

    private init() {
        // Load credentials from Config.plist (not checked into source control)
        // See README for setup instructions
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath) else {
            fatalError("Missing Config.plist — copy Config.plist.example to Config.plist and add your sandbox credentials. See README.")
        }

        guard let id = config["PAYPAL_CLIENT_ID"] as? String, !id.isEmpty,
              let secret = config["PAYPAL_CLIENT_SECRET"] as? String, !secret.isEmpty else {
            fatalError("Config.plist must contain non-empty PAYPAL_CLIENT_ID and PAYPAL_CLIENT_SECRET")
        }

        clientId = id
        clientSecret = secret
        returnDomain = config["RETURN_DOMAIN"] as? String ?? "https://example.com"
    }

    private var cachedAccessToken: String?
    private var tokenExpiry: Date?

    // MARK: - OAuth Access Token

    /// Fetch an OAuth 2.0 access token using client credentials.
    /// Doc reference: Prerequisites, Step 3 -- "Generate an access token"
    func getAccessToken() async throws -> String {
        // Return cached token if still valid
        if let token = cachedAccessToken, let expiry = tokenExpiry, Date() < expiry {
            return token
        }

        let url = URL(string: "\(apiBase)/v1/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Basic auth: base64(clientId:clientSecret)
        let credentials = "\(clientId):\(clientSecret)"
        let base64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data, context: "getAccessToken")

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let token = json["access_token"] as? String else {
            throw AppSwitchError.api("No access_token in OAuth response")
        }

        // Cache token (expires_in is in seconds; subtract 60s buffer)
        let expiresIn = json["expires_in"] as? Int ?? 3600
        cachedAccessToken = token
        tokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn - 60))

        return token
    }

    // MARK: - Create Order (One-Time Payment)

    /// Create an order with app_switch_context for app switch eligibility.
    /// Doc reference: Step 2 -- "One-Time Payment (Orders v2)"
    ///
    /// - Parameters:
    ///   - amount: Dollar amount as a string, e.g. "25.00"
    ///   - osType: "IOS" (from doc: os_type is Required, one of IOS/ANDROID/OTHER)
    ///   - osVersion: Optional OS version string for telemetry
    /// - Returns: Tuple of (orderId, payerActionURL, appSwitchEligible)
    func createOrder(amount: String, osType: String = "IOS", osVersion: String? = nil) async throws -> (orderId: String, payerActionURL: URL, appSwitchEligible: Bool) {
        let token = try await getAccessToken()
        let url = URL(string: "\(apiBase)/v2/checkout/orders")!

        var nativeApp: [String: Any] = [
            "return_app_url": "\(returnDomain)/app-link/return?flow=order",
            "cancel_app_url": "\(returnDomain)/app-link/cancel?flow=order",
            "os_type": osType
        ]
        if let osVersion = osVersion {
            nativeApp["os_version"] = osVersion
        }

        let body: [String: Any] = [
            "intent": "CAPTURE",
            "payment_source": [
                "paypal": [
                    "experience_context": [
                        "user_action": "PAY_NOW",
                        "return_url": "\(returnDomain)/checkout/success?flow=order",
                        "cancel_url": "\(returnDomain)/checkout/cancel?flow=order",
                        "app_switch_context": [
                            "native_app": nativeApp
                        ]
                    ]
                ]
            ],
            "purchase_units": [[
                "amount": [
                    "currency_code": "USD",
                    "value": amount
                ]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "PayPal-Request-Id")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data, context: "createOrder")

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let orderId = json["id"] as? String else {
            throw AppSwitchError.api("No order ID in response")
        }

        // Extract payer-action URL from links array
        // Doc: "For Orders v2, look for rel: payer-action"
        guard let links = json["links"] as? [[String: Any]],
              let payerActionLink = links.first(where: { ($0["rel"] as? String) == "payer-action" }),
              let href = payerActionLink["href"] as? String,
              let payerActionURL = URL(string: href) else {
            throw AppSwitchError.api("No payer-action link in response")
        }

        // Check app_switch_eligibility in response
        let paymentSource = json["payment_source"] as? [String: Any]
        let paypal = paymentSource?["paypal"] as? [String: Any]
        let appSwitchEligible = paypal?["app_switch_eligibility"] as? Bool ?? false

        return (orderId, payerActionURL, appSwitchEligible)
    }

    // MARK: - Capture Order

    /// Capture an approved order.
    /// Doc reference: Step 4 -- "Capture (Orders v2)"
    func captureOrder(orderId: String) async throws -> (status: String, captureId: String?) {
        let token = try await getAccessToken()
        let url = URL(string: "\(apiBase)/v2/checkout/orders/\(orderId)/capture")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "PayPal-Request-Id")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data, context: "captureOrder")

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let status = json["status"] as? String ?? "UNKNOWN"

        // Extract capture ID from purchase_units[0].payments.captures[0].id
        var captureId: String?
        if let units = json["purchase_units"] as? [[String: Any]],
           let payments = units.first?["payments"] as? [String: Any],
           let captures = payments["captures"] as? [[String: Any]] {
            captureId = captures.first?["id"] as? String
        }

        return (status, captureId)
    }

    // MARK: - Create Setup Token (Vault)

    /// Create a setup token with app_switch_context for vaulting.
    /// Doc reference: Step 2 -- "Vaulting (Vault v3)"
    ///
    /// - Returns: Tuple of (setupTokenId, approveURL, appSwitchEligible)
    func createSetupToken(osType: String = "IOS", osVersion: String? = nil) async throws -> (setupTokenId: String, approveURL: URL, appSwitchEligible: Bool) {
        let token = try await getAccessToken()
        let url = URL(string: "\(apiBase)/v3/vault/setup-tokens")!

        var nativeApp: [String: Any] = [
            "return_app_url": "\(returnDomain)/app-link/return?flow=vault",
            "cancel_app_url": "\(returnDomain)/app-link/cancel?flow=vault",
            "os_type": osType
        ]
        if let osVersion = osVersion {
            nativeApp["os_version"] = osVersion
        }

        let body: [String: Any] = [
            "payment_source": [
                "paypal": [
                    "experience_context": [
                        "user_action": "SETUP_NOW",
                        "return_url": "\(returnDomain)/checkout/success?flow=vault",
                        "cancel_url": "\(returnDomain)/checkout/cancel?flow=vault",
                        "app_switch_context": [
                            "native_app": nativeApp
                        ]
                    ],
                    "usage_type": "MERCHANT",
                    "customer_type": "CONSUMER"
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "PayPal-Request-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data, context: "createSetupToken")

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let setupTokenId = json["id"] as? String else {
            throw AppSwitchError.api("No setup token ID in response")
        }

        // Doc: "For Vault v3, look for rel: approve"
        guard let links = json["links"] as? [[String: Any]],
              let approveLink = links.first(where: { ($0["rel"] as? String) == "approve" }),
              let href = approveLink["href"] as? String,
              let approveURL = URL(string: href) else {
            throw AppSwitchError.api("No approve link in response")
        }

        let paymentSource = json["payment_source"] as? [String: Any]
        let paypal = paymentSource?["paypal"] as? [String: Any]
        let appSwitchEligible = paypal?["app_switch_eligibility"] as? Bool ?? false

        return (setupTokenId, approveURL, appSwitchEligible)
    }

    // MARK: - Create Payment Token (Vault)

    /// Exchange a setup token for a permanent payment token after buyer approval.
    /// Doc reference: Step 4 -- "Vault (Vault v3)"
    func createPaymentToken(setupTokenId: String) async throws -> (paymentTokenId: String, status: String) {
        let token = try await getAccessToken()
        let url = URL(string: "\(apiBase)/v3/vault/payment-tokens")!

        let body: [String: Any] = [
            "payment_source": [
                "token": [
                    "id": setupTokenId,
                    "type": "SETUP_TOKEN"
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "PayPal-Request-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data, context: "createPaymentToken")

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let paymentTokenId = json["id"] as? String else {
            throw AppSwitchError.api("No payment token ID in response")
        }
        let status = json["status"] as? String ?? "UNKNOWN"

        return (paymentTokenId, status)
    }

    // MARK: - Charge with Vault ID

    /// Create an order using a previously vaulted payment token.
    /// Doc reference: Step 4 -- "Using a Vault ID for Future Charges"
    func chargeWithVaultId(vaultId: String, amount: String) async throws -> (orderId: String, status: String) {
        let token = try await getAccessToken()
        let url = URL(string: "\(apiBase)/v2/checkout/orders")!

        let body: [String: Any] = [
            "intent": "CAPTURE",
            "payment_source": [
                "paypal": [
                    "vault_id": vaultId
                ]
            ],
            "purchase_units": [[
                "amount": [
                    "currency_code": "USD",
                    "value": amount
                ]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "PayPal-Request-Id")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data, context: "chargeWithVaultId")

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let orderId = json["id"] as? String ?? "UNKNOWN"
        let status = json["status"] as? String ?? "UNKNOWN"

        return (orderId, status)
    }

    // MARK: - Credential Validation

    /// Validate sandbox credentials on app launch.
    /// Returns merchant info on success, throws descriptive error on failure.
    func validateCredentials() async throws -> String {
        // clientId and clientSecret are already guaranteed non-empty by init(),
        // but verify they actually authenticate against the sandbox API.
        do {
            _ = try await getAccessToken()
            return "Connected to PayPal sandbox"
        } catch {
            throw AppSwitchError.api(
                "Invalid credentials. Get sandbox credentials at https://developer.paypal.com/dashboard/applications/sandbox"
            )
        }
    }

    // MARK: - Helpers

    private func validateHTTPResponse(_ response: URLResponse, data: Data, context: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppSwitchError.api("\(context): Not an HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw AppSwitchError.api("\(context): HTTP \(http.statusCode) -- \(body)")
        }
    }
}

// MARK: - Error Type

enum AppSwitchError: LocalizedError {
    case api(String)
    case redirect(String)

    var errorDescription: String? {
        switch self {
        case .api(let msg): return "API Error: \(msg)"
        case .redirect(let msg): return "Redirect Error: \(msg)"
        }
    }
}
