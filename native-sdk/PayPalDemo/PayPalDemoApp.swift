
import SwiftUI

@main
struct PayPalDemoApp: App {

    @StateObject private var coordinator = CheckoutCoordinator()

    var body: some Scene {
        WindowGroup {
            CheckoutFlow()
                .environmentObject(coordinator)
                .onOpenURL { url in
                    coordinator.handleReturnURL(url)
                }
        }
    }
}
