import SwiftUI

struct ReviewsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Reviews")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming soon! This will be where you can review dating apps, venues, and experiences.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Reviews")
        }
    }
}