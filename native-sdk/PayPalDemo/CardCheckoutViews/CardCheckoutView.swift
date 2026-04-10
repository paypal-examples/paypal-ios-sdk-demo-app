import SwiftUI
import CardPayments
import PaymentButtons

struct CardCheckoutView: View {
    @ObservedObject var viewModel: CardPaymentViewModel
    let amount: Double
    let intent: Intent
    let onCheckoutCompleted: (String) -> Void

    @StateObject private var validationViewModel = CardCheckoutValidationViewModel()

    @State private var showAlert: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Card Checkout")
                    .padding(.bottom, 25)
                CardInputField(placeholder: "Card Number", text: $validationViewModel.cardNumber)
                    .onChange(of: validationViewModel.cardNumber) {_, newValue in
                        validationViewModel.updateCardNumber(newValue)
                    }
                HStack(spacing: 10) {
                    CardInputField(placeholder: "MM/YY", text: $validationViewModel.expirationDate)
                        .onChange(of: validationViewModel.expirationDate) {_, newValue in
                            validationViewModel.updateExpirationDate(newValue)
                        }
                    CardInputField(placeholder: "CVV", text: $validationViewModel.cvv)
                        .onChange(of: validationViewModel.cardNumber) {_, newValue in
                            validationViewModel.updateCardNumber(newValue)
                        }
                }
                .padding(.trailing, 20)
                Spacer()
                SubmitButton(title: "Submit") {
                    handleSubmit()
                }
                .padding(20)
            }
            .padding()
            .background(Color.white)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            if isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Processing...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            }
        }
    }

    private func handleSubmit() {

        guard validationViewModel.isValid else {
            errorMessage = validationViewModel.errorMessage
            showAlert = true
            return
        }

        isLoading = true

        Task {
            do {
                let card = Card.createCard(
                    cardNumber: validationViewModel.cardNumber,
                    expirationDate: validationViewModel.expirationDate,
                    cvv: validationViewModel.cvv
                )
                let completedOrder = try await viewModel.checkoutWith(
                    card: card,
                    amount: "\(amount)",
                    intent: intent,
                    sca: .scaWhenRequired
                )
                onCheckoutCompleted(completedOrder.id)
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
                print("Checkout process failed with error: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title)
            .bold()
    }
}

struct CardInputField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(10)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .padding(.trailing, 20)
    }
}

struct SubmitButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(4)
        }
    }
}
