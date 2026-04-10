import CorePayments

enum Environment: String, CaseIterable {
    case sandbox
    case live

    var baseURL: String {
        switch self {
        case .sandbox:
            return "https://ppcp-mobile-demo-sandbox-87bbd7f0a27f.herokuapp.com"

        case .live:
            return "https://paypal-mobile-sdk-demo-server-8dacbcd617ba.herokuapp.com"
        }
    }

    var paypalSDKEnvironment: CorePayments.Environment {
        switch self {
        case .sandbox:
            return .sandbox
        case .live:
            return .live
        }
    }
}
