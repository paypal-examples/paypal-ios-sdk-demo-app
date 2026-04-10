import SwiftUI
import PaymentButtons

struct CartView: View {

    @EnvironmentObject private var coordinator: CheckoutCoordinator

    let items: [Item]
    let isPaymentLink: Bool

    private var totalAmount: Double {
        items.reduce(0, { $0 + $1.amount})
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Cart")
                .font(.largeTitle)
                .padding([.top, .leading])
            
            ForEach(items) { item in
                VStack {
                    CartItemView(item: item)
                }
            }

            Divider()
                .padding(.vertical)
                .padding(.horizontal)
            
            TotalSection(amount: totalAmount)

            Spacer()
            
            VStack(spacing: 10) {
                if isPaymentLink {
                    PaymentButton(
                        title: "Pay Now",
                        imageName: nil,
                        backgroundColor: Color.black,
                        action: {
                            if let url = URL(string: "https://www.sandbox.paypal.com/ncp/payment/BFXRZ54VKCAQ6") {
                                coordinator.openPaymentLink(url: url)
                            }
                        }
                    )
                } else {
                    PayPalButton.Representable(
                        size: .expanded,
                        label: .payWith
                    ){
                        coordinator.startPayPalCheckout(amount: totalAmount)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    PaymentButton(
                        title: "Pay with Card",
                        imageName: nil,
                        backgroundColor: Color.black,
                        action: {
                            coordinator.startCardCheckout(amount: totalAmount)
                        }
                    )
                }


            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }
}


struct CartItemView: View {    
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 15){
            HStack(alignment: .center) {
                if let image1 = item.image {
                    image1
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                }
                
                Spacer()
                
                Text("$\(item.amount, specifier: "%.2f")")
                    .font(.headline)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
    
}

struct TotalSection: View {
    let amount: Double

    var body: some View {
        HStack {
            Text("Total")
                .font(.title2)
            Spacer()
            
            Text("$\(amount, specifier: "%.2f")")
                .font(.title2)
        }
        .padding(.horizontal)
        
    }
    
}

struct PaymentButton: View {
    let title: String
    let imageName: String?
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let imageName = imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                Text(title)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(backgroundColor)
            .cornerRadius(4)
        }
    }
}
