import SwiftUI

/// A button style that provides a subtle scale animation on press
struct ScaleButtonStyle: ButtonStyle {
    let scaleAmount: CGFloat
    
    init(scaleAmount: CGFloat = 0.95) {
        self.scaleAmount = scaleAmount
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}