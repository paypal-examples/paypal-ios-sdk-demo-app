
import SwiftUI

class RedirectHandler: ObservableObject {
    @Published var orderCompleted: Bool = false
    @Published var amount: String = ""
}

@main
struct PayPalDemoApp: App {
    @StateObject private var redirectHandler = RedirectHandler()

    var body: some Scene {
        WindowGroup {
            CheckoutFlow()
                .environmentObject(redirectHandler)
                .onOpenURL { url in
                    print("returned to app with URL: \(url)")
                    if url.host == "success" {
                        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let queryItems = components.queryItems {
                            if let amount = queryItems.first(where: { $0.name == "amt" })?.value {
                                redirectHandler.amount = amount
                                redirectHandler.orderCompleted = true
                            }
                        } else {
                            redirectHandler.orderCompleted = true
                        }
                    } else {
                        redirectHandler.orderCompleted = false
                    }
                }
        }
    }
}
