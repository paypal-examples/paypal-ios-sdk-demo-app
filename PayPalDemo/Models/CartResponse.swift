import Foundation

struct CartResponse: Codable {
    let id: String
    let status: String
    let links: [Link]
    
    struct Link: Codable {
        let href: String
        let rel: String
        let method: String
    }
    
    func extractOrderToken() -> String? {
        guard let payerActionLink = links.first(where: { $0.rel == "payer-action" }),
              let url = URL(string: payerActionLink.href),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            return nil
        }
        return token
    }
}
