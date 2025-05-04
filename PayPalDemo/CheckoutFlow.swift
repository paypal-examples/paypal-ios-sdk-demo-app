import SwiftUI

enum CheckoutStep: Hashable {
    case cardCheckout(amount: Double)
    case complete(orderID: String)
}

struct CheckoutFlow: View {
    @StateObject private var coordinator = CheckoutCoordinator()
    @EnvironmentObject private var redirectHandler: RedirectHandler

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            CartView(
                onPayWithPayPal: { amount in
                    coordinator.startPayPalCheckout(amount: amount)
                },
                onPayWithCard: { amount in
                    coordinator.startCardCheckout(amount: amount)
                }
            )
            .navigationDestination(for: CheckoutStep.self) { step in
                switch step {
                case .cardCheckout(let amount):
                    if let viewModel = coordinator.cardPaymentViewModel {
                        CardCheckoutView(
                            viewModel: viewModel,
                            amount: amount,
                            intent: coordinator.selectedIntent,
                            onCheckoutCompleted: { orderID in
                                coordinator.completeOrder(orderID: orderID)
                            }
                        )
                    }
                case .complete(let orderID):
                    OrderCompleteView(orderID: orderID) {
                        coordinator.reset()
                    }
                }
            }
        }
        .onChange(of: redirectHandler.orderCompleted) { isCompleted in
            if isCompleted {
                coordinator.navigationPath.append(.complete(orderID: redirectHandler.amount))
            }
        }
        .overlay {
            if coordinator.isLoading {
                ProgressView("Processing...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            }
        }
        .alert(isPresented: $coordinator.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(coordinator.paypalErrorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    coordinator.paypalErrorMessage = nil
                }
            )
        }
    }
}
