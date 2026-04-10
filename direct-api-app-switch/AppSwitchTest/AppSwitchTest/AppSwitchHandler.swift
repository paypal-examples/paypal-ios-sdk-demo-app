// AppSwitchHandler.swift
// Handles PayPal app detection, redirect, and return URL parsing.
//
// Doc references:
//   Step 1 -- isPayPalAppInstalled(), SceneDelegate return handling
//   Step 3 -- handlePayerAction(), openBrowserFallback()
//   Step 4 -- Return URL query parameter parsing

import UIKit
import AuthenticationServices

class AppSwitchHandler: NSObject {
    static let shared = AppSwitchHandler()

    /// Callback fired when the buyer returns from PayPal.
    /// Passes (token, payerID) for orders, or (approvalSessionId, nil) for vault.
    var onReturn: ((_ token: String, _ payerID: String?) -> Void)?

    /// Callback fired when the buyer cancels.
    var onCancel: (() -> Void)?

    private var authSession: ASWebAuthenticationSession?
    private weak var presentingWindow: UIWindow?

    private override init() {
        super.init()
    }

    // MARK: - PayPal App Detection

    /// Check if the PayPal app is installed on this device.
    /// Doc: Step 1 -- "Required before passing app_switch_context in the API request."
    ///
    /// Requires Info.plist entry:
    ///   LSApplicationQueriesSchemes: ["paypal-app-switch-checkout"]
    func isPayPalAppInstalled() -> Bool {
        guard let url = URL(string: "paypal-app-switch-checkout://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - Redirect to PayPal

    /// Open the payer-action URL, branching on app switch eligibility.
    /// Doc: Step 3 -- "Extract the payer-action URL ... and branch based on app_switch_eligibility."
    ///
    /// - Parameters:
    ///   - payerActionURL: The URL from the `links` array (rel: "payer-action" or "approve")
    ///   - appSwitchEligible: The `app_switch_eligibility` boolean from the API response
    ///   - window: The presenting window (needed for ASWebAuthenticationSession)
    func handlePayerAction(payerActionURL: URL, appSwitchEligible: Bool, window: UIWindow?) {
        presentingWindow = window

        if appSwitchEligible {
            // Attempt native app switch via universal link
            // Doc: "UIApplication.shared.open with .universalLinksOnly: true"
            UIApplication.shared.open(
                payerActionURL,
                options: [.universalLinksOnly: true]
            ) { [weak self] success in
                if !success {
                    // PayPal app not installed -- fall back to ASWebAuthenticationSession
                    // Doc: "PayPal app not installed ... Fall back to ASWebAuthenticationSession"
                    self?.openBrowserFallback(url: payerActionURL)
                }
            }
        } else {
            // Not eligible for app switch -- go straight to browser
            openBrowserFallback(url: payerActionURL)
        }
    }

    // MARK: - Browser Fallback

    /// Open ASWebAuthenticationSession as a fallback when the PayPal app is not available.
    /// Doc: Step 3 -- iOS 17.4+ uses .https callback (no custom URL scheme needed).
    ///               Earlier iOS uses custom URL scheme.
    private func openBrowserFallback(url: URL) {
        // Detect simulator — .https callback requires Associated Domains which
        // aren't available on simulators. Always use custom URL scheme on simulator.
        #if targetEnvironment(simulator)
        let useCustomScheme = true
        #else
        let useCustomScheme = false
        #endif

        // iOS 17.4+ supports HTTPS-based callback scheme (real devices only)
        // Doc: "iOS 17.4+ supports HTTPS-based ASWebAuthenticationSession callbacks
        //       (no custom URL scheme needed)"
        if #available(iOS 17.4, *), !useCustomScheme {
            // Production path: use HTTPS callback with your verified domain.
            // Replace "example.com" with the domain from your Config.plist RETURN_DOMAIN.
            let returnDomain = Bundle.main.object(forInfoDictionaryKey: "RETURN_DOMAIN") as? String
                ?? (try? NSDictionary(contentsOf: Bundle.main.url(forResource: "Config", withExtension: "plist")!))?["RETURN_DOMAIN"] as? String
                ?? "example.com"

            let session = ASWebAuthenticationSession(
                url: url,
                callback: .https(host: returnDomain, path: "/paypal/return")
            ) { [weak self] callbackURL, error in
                if let callbackURL = callbackURL {
                    self?.handleReturn(url: callbackURL)
                } else if let error = error {
                    print("ASWebAuthenticationSession error: \(error.localizedDescription)")
                    self?.onCancel?()
                }
            }
            session.presentationContextProvider = self
            session.start()
            authSession = session
        } else {
            // Simulator or older iOS -- use custom URL scheme callback.
            // This always works without domain verification.
            // Doc: "Earlier versions require a registered custom URL scheme for the browser fallback."
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "appswitch-test"
            ) { [weak self] callbackURL, error in
                if let callbackURL = callbackURL {
                    self?.handleReturn(url: callbackURL)
                } else if let error = error {
                    print("ASWebAuthenticationSession error: \(error.localizedDescription)")
                    self?.onCancel?()
                }
            }
            session.presentationContextProvider = self
            session.start()
            authSession = session
        }
    }

    // MARK: - Handle Return URL

    /// Parse return URL parameters from PayPal redirect.
    /// Called from both onOpenURL (app switch) and ASWebAuthenticationSession (fallback).
    ///
    /// Doc: Step 4 -- "Return URL Query Parameters"
    ///   Orders flow: token + PayerID
    ///   Vault flow:  approval_session_id (or token_id)
    func handleReturn(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("Invalid return URL: \(url)")
            return
        }

        let queryItems = components.queryItems ?? []

        // Check for cancellation path
        if url.path.contains("cancel") {
            onCancel?()
            return
        }

        // Orders flow: PayPal returns token + PayerID
        if let token = queryItems.first(where: { $0.name == "token" })?.value,
           let payerID = queryItems.first(where: { $0.name == "PayerID" })?.value {
            onReturn?(token, payerID)
            return
        }

        // Vault flow: PayPal returns approval_session_id (or token_id)
        // Doc: "Vault flow: PayPal returns approval_session_id (or token_id)"
        if let approvalSessionId = queryItems.first(where: { $0.name == "approval_session_id" })?.value
            ?? queryItems.first(where: { $0.name == "token_id" })?.value {
            onReturn?(approvalSessionId, nil)
            return
        }

        // Fallback: check for just a token (no PayerID) -- could be vault token param
        if let token = queryItems.first(where: { $0.name == "token" })?.value {
            onReturn?(token, nil)
            return
        }

        print("Unrecognized return URL parameters: \(url)")
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AppSwitchHandler: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return presentingWindow ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? UIWindow()
    }
}
