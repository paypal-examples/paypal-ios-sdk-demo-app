import Foundation

struct CreateCartParams: Encodable {
    let items: [CartItem]
    let customer: Customer
    let paymentMethod: PaymentMethod
    
    struct CartItem: Encodable {
        let itemId: String
        let quantity: Int
        
        enum CodingKeys: String, CodingKey {
            case itemId = "item_id"
            case quantity
        }
    }
    
    struct Customer: Encodable {
        let name: Name
        let emailAddress: String
        let phone: Phone
        
        struct Name: Encodable {
            let givenName: String
            let surname: String
            
            enum CodingKeys: String, CodingKey {
                case givenName = "given_name"
                case surname
            }
        }
        
        struct Phone: Encodable {
            let countryCode: String
            let nationalNumber: String
            
            enum CodingKeys: String, CodingKey {
                case countryCode = "country_code"
                case nationalNumber = "national_number"
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case name
            case emailAddress = "email_address"
            case phone
        }
    }
    
    struct PaymentMethod: Encodable {
        let paypal: PayPalMethod
        
        struct PayPalMethod: Encodable {
            let experienceContext: ExperienceContext
            
            struct ExperienceContext: Encodable {
                let returnUrl: String
                let cancelUrl: String
                let shippingAddressPreference: String
                
                enum CodingKeys: String, CodingKey {
                    case returnUrl = "return_url"
                    case cancelUrl = "cancel_url"
                    case shippingAddressPreference = "shipping_address_preference"
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case experienceContext = "experience_context"
            }
        }
    }
}
