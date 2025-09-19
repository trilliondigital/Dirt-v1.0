import SwiftUI

struct HomeView: View {
    @StateObject private var coordinator = NavigationCoordinator.shared
    
    var body: some View {
        MaterialGlassNavigationContainer {
            NavigationRouter.TabContentContainer(coordinator: coordinator)
        }
        .withNavigationCoordinator(coordinator)
        .onOpenURL { url in
            coordinator.handleDeepLink(url)
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
