import SwiftUI

class CheckoutCoordinator: ObservableObject {
    @Published var navigationPath: [CheckoutStep] = []
    @Published var cardPaymentViewModel: CardPaymentViewModel?
    @Published var payPalViewModel: PayPalViewModel?
    @Published var selectedIntent: Intent = .capture
    
    func startCardCheckout(amount: Double) {
        DispatchQueue.main.async {
            self.cardPaymentViewModel = CardPaymentViewModel()
            self.navigationPath.append(.cardCheckout(amount: amount))
        }
    }
    
    func startPayPalCheckout() {
        DispatchQueue.main.async {
            self.payPalViewModel = PayPalViewModel()
            self.payPalViewModel?.startCheckout()
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
