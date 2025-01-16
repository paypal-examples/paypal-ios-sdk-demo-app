
import SwiftUI

enum CheckoutStep: Hashable {
    case cardCheckout(amount: Double)
    case complete(orderID: String)
}

@main
struct PayPalDemoApp: App {
    @StateObject private var coordinator = CheckoutCoordinator()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.navigationPath) {
                CartView()
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
            .environmentObject(coordinator)
        }
    }
}
