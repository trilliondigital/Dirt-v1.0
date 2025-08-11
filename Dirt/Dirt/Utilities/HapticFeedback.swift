import UIKit

enum HapticFeedback {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }
    
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
    }
    
     // Compatibility aliases used across the app
     static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
         notify(type)
     }
     
     static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
         notify(type)
     }
}
