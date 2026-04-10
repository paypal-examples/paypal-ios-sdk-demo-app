// ContentView.swift
// Single-screen test UI for both one-time payment and vault flows.

import SwiftUI

struct ContentView: View {
    @State private var statusText = "Ready"
    @State private var orderId: String?
    @State private var captureId: String?
    @State private var vaultId: String?
    @State private var isLoading = false
    @State private var paypalAppInstalled = false
    @State private var credentialStatus: String?
    @State private var credentialsValid = false

    private let service = PayPalService.shared
    private let handler = AppSwitchHandler.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // -- Credential Status Banner --
                    if let credentialStatus = credentialStatus {
                        Text(credentialStatus)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(credentialsValid ? .green : .red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(credentialsValid
                                          ? Color.green.opacity(0.1)
                                          : Color.red.opacity(0.1))
                            )
                    }

                    // -- Device Info --
                    GroupBox(label: Label("Device", systemImage: "iphone")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("PayPal App Installed:")
                                Spacer()
                                Text(paypalAppInstalled ? "Yes" : "No")
                                    .foregroundColor(paypalAppInstalled ? .green : .orange)
                                    .bold()
                            }
                            HStack {
                                Text("iOS Version:")
                                Spacer()
                                Text(UIDevice.current.systemVersion)
                            }
                            HStack {
                                Text("iOS 17.4+ (HTTPS callback):")
                                Spacer()
                                if #available(iOS 17.4, *) {
                                    Text("Yes").foregroundColor(.green).bold()
                                } else {
                                    Text("No").foregroundColor(.orange).bold()
                                }
                            }
                        }
                        .font(.subheadline)
                    }

                    // -- Status --
                    GroupBox(label: Label("Status", systemImage: "info.circle")) {
                        Text(statusText)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(statusText.contains("Error") ? .red : .primary)
                    }

                    // -- Action Buttons --
                    GroupBox(label: Label("Actions", systemImage: "creditcard")) {
                        VStack(spacing: 12) {
                            Button(action: startPayment) {
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                    Text("Pay $25.00")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isLoading)

                            Button(action: startVault) {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                    Text("Save PayPal")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isLoading)
                        }
                    }

                    // -- Results --
                    if orderId != nil || captureId != nil || vaultId != nil {
                        GroupBox(label: Label("Results", systemImage: "checkmark.seal")) {
                            VStack(alignment: .leading, spacing: 8) {
                                if let orderId = orderId {
                                    resultRow("Order ID", orderId)
                                }
                                if let captureId = captureId {
                                    resultRow("Capture ID", captureId)
                                }
                                if let vaultId = vaultId {
                                    resultRow("Vault ID", vaultId)
                                }
                            }
                        }
                    }

                    // -- Loading Indicator --
                    if isLoading {
                        ProgressView("Processing...")
                            .padding()
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("App Switch Test")
            .task {
                paypalAppInstalled = handler.isPayPalAppInstalled()
                setupReturnHandlers()

                // Validate credentials on launch
                do {
                    let message = try await service.validateCredentials()
                    credentialsValid = true
                    credentialStatus = "\u{2705} \(message)"
                } catch {
                    credentialsValid = false
                    credentialStatus = "\u{274C} Missing or invalid credentials \u{2014} see README"
                }
            }
        }
    }

    // MARK: - One-Time Payment Flow

    /// 1. Create order with app_switch_context
    /// 2. Redirect buyer to PayPal (app switch or browser fallback)
    /// 3. On return, capture the order
    private func startPayment() {
        isLoading = true
        orderId = nil
        captureId = nil
        updateStatus("Creating order...")

        let osVersion = UIDevice.current.systemVersion

        Task {
            do {
                let result = try await service.createOrder(
                    amount: "25.00",
                    osType: "IOS",
                    osVersion: osVersion
                )

                await MainActor.run {
                    orderId = result.orderId
                    updateStatus("Order \(result.orderId) created. Eligible: \(result.appSwitchEligible). Redirecting...")

                    let window = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .flatMap { $0.windows }
                        .first(where: { $0.isKeyWindow })

                    handler.handlePayerAction(
                        payerActionURL: result.payerActionURL,
                        appSwitchEligible: result.appSwitchEligible,
                        window: window
                    )
                }
            } catch {
                await MainActor.run {
                    updateStatus("Error: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Vault Flow

    /// 1. Create setup token with app_switch_context
    /// 2. Redirect buyer to PayPal for approval
    /// 3. On return, create payment token
    private func startVault() {
        isLoading = true
        vaultId = nil
        updateStatus("Creating setup token...")

        let osVersion = UIDevice.current.systemVersion

        Task {
            do {
                let result = try await service.createSetupToken(
                    osType: "IOS",
                    osVersion: osVersion
                )

                await MainActor.run {
                    updateStatus("Setup token \(result.setupTokenId) created. Eligible: \(result.appSwitchEligible). Redirecting...")

                    let window = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .flatMap { $0.windows }
                        .first(where: { $0.isKeyWindow })

                    handler.handlePayerAction(
                        payerActionURL: result.approveURL,
                        appSwitchEligible: result.appSwitchEligible,
                        window: window
                    )
                }
            } catch {
                await MainActor.run {
                    updateStatus("Error: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Return Handlers

    private func setupReturnHandlers() {
        handler.onReturn = { [self] token, payerID in
            Task { @MainActor in
                if let payerID = payerID {
                    // Orders flow -- capture the order
                    updateStatus("Buyer returned. Token: \(token), PayerID: \(payerID). Capturing...")
                    orderId = token
                    do {
                        let capture = try await service.captureOrder(orderId: token)
                        captureId = capture.captureId
                        updateStatus("Capture \(capture.status). ID: \(capture.captureId ?? "n/a")")
                    } catch {
                        updateStatus("Capture error: \(error.localizedDescription)")
                    }
                    isLoading = false
                } else {
                    // Vault flow -- create payment token
                    updateStatus("Buyer approved. Session: \(token). Creating payment token...")
                    do {
                        let vault = try await service.createPaymentToken(setupTokenId: token)
                        vaultId = vault.paymentTokenId
                        updateStatus("Vaulted! Token: \(vault.paymentTokenId), Status: \(vault.status)")
                    } catch {
                        updateStatus("Vault error: \(error.localizedDescription)")
                    }
                    isLoading = false
                }
            }
        }

        handler.onCancel = { [self] in
            Task { @MainActor in
                updateStatus("Buyer cancelled.")
                isLoading = false
            }
        }
    }

    // MARK: - Helpers

    private func updateStatus(_ text: String) {
        statusText = text
        print("[AppSwitchTest] \(text)")
    }

    @ViewBuilder
    private func resultRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.system(.caption, design: .monospaced))
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
