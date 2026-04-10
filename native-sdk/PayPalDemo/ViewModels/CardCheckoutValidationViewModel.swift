import Foundation
import CardPayments

class CardCheckoutValidationViewModel: ObservableObject {
    @Published var errorMessage: String = ""
    
    @Published var cardNumber: String = "4111 1111 1111 1111"
    @Published var expirationDate: String = "01 / 27"
    @Published var cvv: String = "123"

    private let cardFormatter = CardFormatter()

    var isValid: Bool {
        return Card.isCardFormValid(cardNumber: cardNumber, expirationDate: expirationDate, cvv: cvv)
    }

    func isCardValid(completion: (Card?) -> Void) {
        if isValid {
            let card = Card.createCard(cardNumber: cardNumber, expirationDate: expirationDate, cvv: cvv)
            completion(card)
        } else {
            errorMessage = "Invalid card details. Please check and try again."
            completion(nil)
        }
    }

    func updateCardNumber(_ newValue: String) {
        cardNumber = cardFormatter.formatFieldWith(cardNumber, field: .cardNumber)
        cvv = CardType.unknown.getCardType(cardNumber) == .americanExpress ? "1234" : "123"
    }

    func updateExpirationDate(_ newValue: String) {
        expirationDate = cardFormatter.formatFieldWith(newValue, field: .expirationDate)
    }

    func updateCVV(_ newValue: String) {
        cvv = cardFormatter.formatFieldWith(cvv, field: .cvv)
    }
}

extension Card {
    static func createCard(cardNumber: String, expirationDate: String, cvv: String) -> Card {
        let cleanedCardText = cardNumber.replacingOccurrences(of: " ", with: "")

        let expirationComponents = expirationDate.components(separatedBy: " / ")
        let expirationMonth = expirationComponents[0]
        let expirationYear = "20" + expirationComponents[1]

        return Card(number: cleanedCardText, expirationMonth: expirationMonth, expirationYear: expirationYear, securityCode: cvv)
    }

    static func isCardFormValid(cardNumber: String, expirationDate: String, cvv: String) -> Bool {
        let cleanedCardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        let cleanedExpirationDate = expirationDate.replacingOccurrences(of: " / ", with: "")

        let enabled = cleanedCardNumber.count >= 15 && cleanedCardNumber.count <= 19
        && cleanedExpirationDate.count == 4 && cvv.count >= 3 && cvv.count <= 4
        return enabled
    }
}
