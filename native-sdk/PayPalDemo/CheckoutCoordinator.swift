import SwiftUI

class CheckoutCoordinator: ObservableObject {
    @Published var navigationPath: [CheckoutStep] = []
    @Published var selectedIntent: Intent = .capture

    @Published var cardPaymentViewModel: CardPaymentViewModel?

    @Published var payPalViewModel: PayPalViewModel?
    @Published var paypalErrorMessage: String?
    @Published var isLoading = false
    @Published var showAlert = false

    func startCardCheckout(amount: Double) {
        DispatchQueue.main.async {
            self.cardPaymentViewModel = CardPaymentViewModel()
            self.navigationPath.append(.cardCheckout(amount: amount))
        }
    }

    func startPayPalCheckout(amount: Double) {
        isLoading = true
        DispatchQueue.main.async {
            self.payPalViewModel = PayPalViewModel()
            Task {
                do {
                    guard let viewModel = self.payPalViewModel else { return }
                    let completedOrderID = try await viewModel.startCheckout(
                        amount: amount,
                        intent: self.selectedIntent
                    )

                    self.isLoading = false
                    if let completedOrderID {
                        self.completeOrder(orderID: completedOrderID)
                    } else {
                        print("Session Canceled by user")
                    }
                } catch {
                    self.isLoading = false
                    self.showAlert = true
                    self.paypalErrorMessage = error.localizedDescription
                }
            }
        }
    }

    func completeOrder(orderID: String) {
        DispatchQueue.main.async {
            self.navigationPath.append(.complete(orderID: orderID))
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.navigationPath.removeAll()
            self.cardPaymentViewModel = nil
            self.payPalViewModel = nil
        }
    }
}

import UIKit

extension CheckoutCoordinator {
    func openPaymentLink(url: URL) {
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                print("✅ Successfully opened payment link: \(url)")
            } else {
                print("❌ Failed to open payment link.")
                self.paypalErrorMessage = "Unable to open payment link."
                self.showAlert = true
            }
        }
    }

    func handleReturnURL(_ url: URL) {
        print("↩️ Returned to app with URL: \(url.absoluteString)")
        guard url.path == "/success" else {
            print("❌ Not a success URL")
            return
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let amount = components.queryItems?.first(where: { $0.name == "amt" })?.value {
            navigationPath.append(.paymentLinkComplete(amount: amount))
        }
    }
}
