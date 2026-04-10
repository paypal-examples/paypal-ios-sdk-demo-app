struct CreateOrderParams: Encodable {

    let applicationContext: ApplicationContext?
    let intent: String
    var purchaseUnits: [PurchaseUnit]?
}

struct ApplicationContext: Codable {

    let userAction: String

    enum CodingKeys: String, CodingKey {
        case userAction
    }
}

struct PurchaseUnit: Encodable {
    let amount: Amount
}
struct Amount: Encodable {
    let currencyCode: String
    let value: String
}
