import SwiftUI
import PaymentButtons

struct CartView: View {

    var onPayWithPayPal: (Double) -> Void
    var onPayWithCard: (Double) -> Void

    let items: [Item] = [
        Item(name: "10 Credit Points", imageName: "gold", amount: 19.99)
        ]
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
                PaymentButton(
                    title: "Pay Now",
                    imageName: nil,
                    backgroundColor: Color(hex: "FFC439")!,
                    action: {
                        guard let url = URL(string: "https://www.sandbox.paypal.com/ncp/payment/BFXRZ54VKCAQ6") else { return }
                        UIApplication.shared.open(url)
                    }
                    )
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
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
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
            .foregroundColor(.black)
            .background(backgroundColor)
            .cornerRadius(4)
        }
    }
}

extension Color {
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.replacingOccurrences(of: "#", with: "")

        guard let int = UInt64(hex, radix: 16) else { return nil }

        let r, g, b, a: Double

        switch hex.count {
        case 6: // RGB
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            a = 1.0

        case 8: // RGBA
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8) & 0xFF) / 255
            a = Double(int & 0xFF) / 255

        default:
            return nil
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
