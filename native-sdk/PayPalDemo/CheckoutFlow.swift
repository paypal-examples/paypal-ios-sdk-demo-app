import SwiftUI

enum CheckoutStep: Hashable {
    case cardCheckout(amount: Double)
    case complete(orderID: String)
    case paymentLinkComplete(amount: String)
}

struct CheckoutFlow: View {
    @EnvironmentObject private var coordinator: CheckoutCoordinator
    @State var isPaymentLink = true

    var body: some View {

        NavigationStack(path: $coordinator.navigationPath) {
            VStack(spacing: 20) {
                Picker("CheckoutMethod", selection: $isPaymentLink) {
                    Text("Use Payment Link").tag(true)
                    Text("Use Native Checkout").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                if isPaymentLink {
                    CartView(
                        items: [
                            Item(name: "10 Credit Points", image: Image("gold"), amount: 19.99)
                        ],
                        isPaymentLink: true
                    )
                } else {
                    CartView(
                        items: [
                            Item(name: "White T-Shirt", image: Image(systemName: "tshirt"), amount: 29.99)
                        ],
                        isPaymentLink: false
                    )
                }
            }
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
                case .paymentLinkComplete(let amount):
                    PaymentLinkCompleteView(amount: amount) {
                        coordinator.reset()
                    }
                }
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

#Preview {
    CheckoutFlow()
}
