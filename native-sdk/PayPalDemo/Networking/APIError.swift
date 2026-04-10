import Foundation

enum APIError: Error {
    case unauthorized
    case dataParsingError
    case networkError(URLError)
    case serverError(statusCode: Int)
    case invalidURL
    case unknown
    case httpResponseError
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return NSLocalizedString("You are not authorized to perform this action.", comment: "APIError: unauthorized")
        case .dataParsingError:
            return NSLocalizedString("Failed to decode the server resposne", comment: "APIError: dataParsingError")
        case .networkError(let urlError):
            return NSLocalizedString("Network error has occurred: \(urlError.localizedDescription)", comment: "APIError: networkError")
        case .serverError(let statusCode):
            return NSLocalizedString("Server error \(statusCode)", comment: "APIError: serverError")
        case .httpResponseError:
            return NSLocalizedString("The provided URL was invalid.", comment: "APIError: htttpResponseError")
        case .invalidURL:
            return NSLocalizedString("The provided URL was invalid.", comment: "APIError: invalidURL")
        case .unknown:
            return NSLocalizedString("An unknown error has occurred", comment: "APIError: unknown")
        }
    }
}
