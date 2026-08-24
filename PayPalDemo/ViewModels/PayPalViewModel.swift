import SwiftUI
import PayPalPayments
import CorePayments
import FraudProtection

class PayPalViewModel: ObservableObject {

    private var payPalClient: PayPalClient?
    private var payPalDataCollector: PayPalDataCollector?

    func startCheckout(
        amount: Double,
        intent: Intent
    ) async throws -> String? {
        let config = try await DemoMerchantAPI.shared.getCoreConfig()

        let order = try await DemoMerchantAPI.shared.createOrder(
            orderParams: CreateOrderParams(
                applicationContext: nil,
                intent: intent.rawValue,
                purchaseUnits: [PurchaseUnit(amount: Amount(currencyCode: "USD", value: "\(amount)"))]
            )
        )
        print("✅ Order created with orderID: \(order.id) with status: \(order.status)")

        payPalClient = PayPalClient(config: config)
        guard let payPalClient = payPalClient else {
            throw NSError(domain: "PayPalWebCheckoutClientError", code: -1, userInfo: [NSLocalizedDescriptionKey: "PayPalWebCheckout client could not be initialized."])
        }
        
        let urlConfig = try DemoMerchantAPI.shared.makePayPalURLConfig()
        payPalClient.createPayPalSession(sessionType: .checkout, urlConfig: urlConfig)
        
        payPalDataCollector = PayPalDataCollector(config: config)
        let payPalClientMetadataID = payPalDataCollector?.collectDeviceData()
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
            payPalClient.start(orderID: order.id) { result in
                switch result {
                case .success(let successResult):
                    print("✅ Order approved with orderID: \(successResult.orderID) and PayerID: \(successResult.payerID)")
                    Task {
                        do {
                            let completedOrder = try await DemoMerchantAPI.shared.completeOrder(
                                orderID: order.id,
                                payPalClientMetadataID: payPalClientMetadataID,
                                intent: intent
                            )

                            print("✅ Capture returned with orderID: \(completedOrder.id) with status: \(completedOrder.status) ")
                            continuation.resume(returning: completedOrder.id)
                        } catch {
                            // Convenience method if separate handling of cancel error is needed
                            if PayPalError.isCheckoutCanceled(error) {
                                continuation.resume(returning: nil)
                            } else {
                                continuation.resume(throwing: error)
                            }
                        }

                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

        }
    }
}
