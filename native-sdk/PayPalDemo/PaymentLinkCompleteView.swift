import SwiftUI
struct PaymentLinkCompleteView: View {
    let amount: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Order Complete")
                .padding(.bottom, 25)
            Text("Thank you for your order! Your amount is \(amount)")
                .font(.subheadline)
                .padding(.bottom)
            Spacer()
            SubmitButton(title: "Done", action: onDismiss)
        }
        .padding()
        .background(Color.white)
    }
}
