import Foundation

enum ErrorPresenter {
    static func message(for error: Error) -> String {
        let ns = error as NSError
        switch (ns.domain, ns.code) {
        case (NSURLErrorDomain, _):
            return NSLocalizedString("Network issue. Check your connection and try again.", comment: "")
        case ("SupabaseFunction", 429):
            return NSLocalizedString("Too many requests. Please wait a moment and try again.", comment: "")
        case ("SupabaseFunction", 500...599):
            return NSLocalizedString("Server is having trouble. We’re on it—try again shortly.", comment: "")
        default:
            if let text = ns.userInfo[NSLocalizedDescriptionKey] as? String, !text.isEmpty {
                return text
            }
            return NSLocalizedString("Something went wrong. Please try again.", comment: "")
        }
    }
}
