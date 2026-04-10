import SwiftUI

struct OrderCompleteView: View {
    let orderID: String
    var onDone: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Order Complete")
                .padding(.bottom, 25)
            Text("Thank you for your order! Your order number is \(orderID)")
                .font(.subheadline)
                .padding(.bottom)
            Spacer()
            SubmitButton(title: "Done", action: onDone)
        }
        .padding()
        .background(Color.white)
    }
}
