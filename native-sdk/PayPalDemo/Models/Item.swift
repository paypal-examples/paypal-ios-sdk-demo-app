import Foundation
import SwiftUI

struct Item: Identifiable {
    let id: String = UUID().uuidString
    let name: String
    let image: Image?
    let amount: Double
}
