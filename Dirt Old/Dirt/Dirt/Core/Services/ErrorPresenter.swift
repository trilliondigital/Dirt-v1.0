import Foundation
import SwiftUI

enum ErrorPresenter {
    static func message(for error: Error) -> String {
        let ns = error as NSError
        switch (ns.domain, ns.code) {
        case (NSURLErrorDomain, _):
            return NSLocalizedString("Network issue. Check your connection and try again.", comment: "")
        case ("SupabaseFunction", 429):
            return NSLocalizedString("Too many requests. Please wait a moment and try again.", comment: "")
        case ("SupabaseFunction", 500...599):
            return NSLocalizedString("Server is having trouble. We're on it—try again shortly.", comment: "")
        default:
            if let text = ns.userInfo[NSLocalizedDescriptionKey] as? String, !text.isEmpty {
                return text
            }
            return NSLocalizedString("Something went wrong. Please try again.", comment: "")
        }
    }
    
    /// Determine the appropriate toast type for an error
    static func toastType(for error: Error) -> GlassToast.ToastType {
        let ns = error as NSError
        
        // Check if it's an AppError first
        if let appError = error as? AppError {
            switch appError {
            case .network(.noConnection), .network(.timeout):
                return .warning
            case .network(.unauthorized), .authentication:
                return .warning
            case .validation:
                return .info
            case .storage(.diskFull):
                return .warning
            default:
                return .error
            }
        }
        
        // Handle NSError cases
        switch (ns.domain, ns.code) {
        case (NSURLErrorDomain, NSURLErrorNotConnectedToInternet),
             (NSURLErrorDomain, NSURLErrorNetworkConnectionLost),
             (NSURLErrorDomain, NSURLErrorTimedOut):
            return .warning
        case ("SupabaseFunction", 429):
            return .warning
        case ("SupabaseFunction", 401), ("SupabaseFunction", 403):
            return .warning
        case ("SupabaseFunction", 400...499):
            return .info
        default:
            return .error
        }
    }
    
    /// Create a Material Glass toast for an error
    static func createGlassToast(for error: Error) -> GlassToast {
        let message = self.message(for: error)
        let type = self.toastType(for: error)
        return GlassToast(message: message, type: type)
    }
}

// MARK: - View Extension for Error Presentation

extension View {
    /// Present an error using a Material Glass toast notification
    func presentGlassToast(for error: Error?) -> some View {
        self.overlay(
            Group {
                if let error = error {
                    ErrorPresenter.createGlassToast(for: error)
                        .transition(MaterialMotion.Transition.slideDown)
                        .zIndex(1000)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 60) // Account for safe area and navigation
                        .padding(.horizontal, UISpacing.md)
                }
            }
        )
    }
    
    /// Present an error with a custom message using Material Glass toast
    func presentGlassToast(message: String, type: GlassToast.ToastType = .error) -> some View {
        self.overlay(
            GlassToast(message: message, type: type)
                .transition(MaterialMotion.Transition.slideDown)
                .zIndex(1000)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 60)
                .padding(.horizontal, UISpacing.md)
        )
    }
}