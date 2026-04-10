import SwiftUI
import PayPalWebPayments
import CorePayments
import FraudProtection

class PayPalViewModel: ObservableObject {

    private var payPalWebCheckoutClient: PayPalWebCheckoutClient?
    private var payPalDataCollector: PayPalDataCollector?

    func startCheckout(
        amount: Double,
        intent: Intent
    ) async throws -> String? {
        async let config = try await DemoMerchantAPI.shared.getCoreConfig()

        let order = try await DemoMerchantAPI.shared.createOrder(
            orderParams: CreateOrderParams(
                applicationContext: nil,
                intent: intent.rawValue,
                purchaseUnits: [PurchaseUnit(amount: Amount(currencyCode: "USD", value: "\(amount)"))]
            )
        )
        print("✅ Order created with orderID: \(order.id) with status: \(order.status)")

        payPalWebCheckoutClient = try await PayPalWebCheckoutClient(config: config)
        guard let payPalWebCheckoutClient = payPalWebCheckoutClient else {
            throw NSError(domain: "PayPalWebCheckoutClientError", code: -1, userInfo: [NSLocalizedDescriptionKey: "PayPalWebCheckout client could not be initialized."])
        }

        payPalDataCollector = try await PayPalDataCollector(config: config)
        let payPalClientMetadataID = payPalDataCollector?.collectDeviceData()

        do {
            let paypalCheckoutResult = try await payPalWebCheckoutClient.start(
                request: PayPalWebCheckoutRequest(
                    orderID: order.id,
                    fundingSource: .paypal)
            )
            print("✅ Order approved with orderID: \(paypalCheckoutResult.orderID) and PayerID: \(paypalCheckoutResult.payerID)")

            let completedOrder = try await DemoMerchantAPI.shared.completeOrder(
                orderID: order.id,
                payPalClientMetadataID: payPalClientMetadataID,
                intent: intent
            )
            print("✅ Capture returned with orderID: \(completedOrder.id) with status: \(completedOrder.status) ")
            return completedOrder.id
        } catch {
            // Convenience method if separate handling of cancel error is needed
            if PayPalError.isCheckoutCanceled(error) {
                return nil
            } else {
                throw error
            }
        }
    }
}
