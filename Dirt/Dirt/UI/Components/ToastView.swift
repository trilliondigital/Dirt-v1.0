import SwiftUI

public struct ToastMessage: Identifiable, Equatable {
    public enum Style { case success, error, info }
    public let id = UUID()
    public let style: Style
    public let text: String
}

public final class ToastCenter: ObservableObject {
    @Published public var message: ToastMessage?
    public init() {}
    public func show(_ style: ToastMessage.Style, _ text: String) {
        withAnimation { self.message = ToastMessage(style: style, text: text) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { self.message = nil }
        }
    }
}

public struct ToastView: View {
    @EnvironmentObject var center: ToastCenter
    public init() {}
    public var body: some View {
        VStack {
            if let msg = center.message {
                HStack(spacing: 8) {
                    Image(systemName: icon(for: msg.style))
                    Text(msg.text)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .background(background(for: msg.style))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 12)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: center.message)
    }

    private func icon(for style: ToastMessage.Style) -> String {
        switch style {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    private func background(for style: ToastMessage.Style) -> Color {
        switch style {
        case .success: return Color.green.opacity(0.9)
        case .error: return Color.orange.opacity(0.95)
        case .info: return Color.blue.opacity(0.9)
        }
    }
}

public extension View {
    func withToasts(_ center: ToastCenter) -> some View {
        self.environmentObject(center)
            .overlay(ToastView().environmentObject(center), alignment: .top)
    }
}
