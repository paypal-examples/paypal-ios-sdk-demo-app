import Foundation
import CardPayments
import CorePayments
import FraudProtection

class CardPaymentViewModel: ObservableObject {

    private var cardClient: CardClient?
    private var payPalDataCollector: PayPalDataCollector?

    func checkoutWith(
        card: Card,
        amount: String,
        intent: Intent,
        sca: SCA
    ) async throws -> Order {
        do {
            async let config = try await DemoMerchantAPI.shared.getCoreConfig()

            let order = try await DemoMerchantAPI.shared.createOrder(
                orderParams: CreateOrderParams(
                    applicationContext: nil,
                    intent: intent.rawValue,
                    purchaseUnits: [PurchaseUnit(amount: Amount(currencyCode: "USD", value: amount))]
                )
            )
            print("✅ Order created with orderID: \(order.id) with status: \(order.status)")

            cardClient = try await CardClient(config: config)
            guard let cardClient = cardClient else {
                throw NSError(domain: "CardClientError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Card client could not be initialized."])
            }

            let cardRequest = CardRequest(orderID: order.id, card: card, sca: sca)
            let cardResult = try await cardClient.approveOrder(request: cardRequest)
            print("✅ Card approval returned with CardResult \norderID: \(cardResult.orderID) \nstatus: \(String(describing: cardResult.status)) \ndidAttemptThreeDSecureAuthentication: \(cardResult.didAttemptThreeDSecureAuthentication)")

            payPalDataCollector = try await PayPalDataCollector(config: config)
            let payPalClientMetadataID = payPalDataCollector?.collectDeviceData()

            let completedOrder = try await DemoMerchantAPI.shared.completeOrder(
                orderID: order.id,
                payPalClientMetadataID: payPalClientMetadataID,
                intent: intent)
            print("✅ Capture returned with orderID: \(completedOrder.id) with status: \(completedOrder.status) ")
            return completedOrder
        } catch let error {
            print("❌ Failed in checkout with card: \(error.localizedDescription)")
            throw error
        }
    }
}
