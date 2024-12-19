import SwiftUI


struct CartView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Cart")
                .font(.largeTitle)
                .padding([.top, .leading])
            
            CartItemView()
            
            Divider()
                .padding(.vertical)
                .padding(.horizontal)
            
            TotalSection()
            
            Spacer()
            
            VStack(spacing: 10) {
                PaymentButton(
                    title: "Pay with PayPal",
                    imageName: "paypal_color_monogram",
                    backgroundColor: Color.yellow,
                    action: {
                        
                    })
                
                PaymentButton(
                    title: "Pay with Card",
                    imageName: nil,
                    backgroundColor: Color.black,
                    action: {
                        
                    })
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }
}


struct CartItemView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15){
            HStack{
                Image(systemName: "tshirt")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text("White T-Shirt")
                        .font(.headline)
                }
                
                Spacer()
                
                Text("$29.99")
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
    var body: some View {
        HStack {
            Text("Total")
                .font(.title2)
            Spacer()
            
            Text("$29.99")
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
            .cornerRadius(10)
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
    }
}
