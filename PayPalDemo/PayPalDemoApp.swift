
import SwiftUI

@main
struct PayPalDemoApp: App {
    var body: some Scene {
        WindowGroup {
            CheckoutFlow()
                .onOpenURL { url in
                    print("returned to app with URL: \(url)")
                }
        }
    }
}
