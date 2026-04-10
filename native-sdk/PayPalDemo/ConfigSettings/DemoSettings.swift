import Foundation

enum DemoSettings {

    static var environment: Environment {
        // give toggle option when testing .live
        return .sandbox
    }
}
