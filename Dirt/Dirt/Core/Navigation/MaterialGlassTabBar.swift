import SwiftUI

// MARK: - Material Glass Tab Bar
/// A Material Glass implementation of the main tab bar with enhanced animations and haptic feedback
struct MaterialGlassTabBar: View {
    @ObservedObject var coordinator: NavigationCoordinator
    
    private let tabs: [MainTab] = MainTab.allCases
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: coordinator.selectedTab == tab,
                    action: {
                        coordinator.navigateToTab(tab)
                    }
                )
            }
        }
        .padding(.horizontal, UISpacing.sm)
        .padding(.top, UISpacing.xs)
        .padding(.bottom, UISpacing.sm)
        .background(
            MaterialDesignSystem.Context.tabBar,
            in: Rectangle()
        )
        .overlay(
            // Top border
            Rectangle()
                .frame(height: 1)
                .foregroundColor(MaterialDesignSystem.GlassBorders.subtle)
                .frame(maxHeight: .infinity, alignment: .top)
        )
        .shadow(
            color: MaterialDesignSystem.GlassShadows.soft,
            radius: 8,
            x: 0,
            y: -2
        )
    }
}

// MARK: - Tab Bar Button
private struct TabBarButton: View {
    let tab: MainTab
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: UISpacing.xxs) {
                // Tab icon with selection animation
                ZStack {
                    // Background circle for selected state
                    if isSelected {
                        Circle()
                            .fill(MaterialDesignSystem.GlassColors.primary)
                            .frame(width: 32, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: isSelected ? tab.selectedSystemImage : tab.systemImage)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? UIColors.accentPrimary : UIColors.secondaryLabel)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(height: 32)
                
                // Tab title
                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? UIColors.accentPrimary : UIColors.secondaryLabel)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, UISpacing.xs)
            .contentShape(Rectangle()) // Expand touch area
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(MaterialMotion.Interactive.tabSelection(), value: isSelected)
        .animation(MaterialMotion.Spring.quick, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Material Glass Navigation Container
/// Container view that provides Material Glass navigation with tab bar
struct MaterialGlassNavigationContainer<Content: View>: View {
    @StateObject private var coordinator = NavigationCoordinator.shared
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack(alignment: .bottom) {
                // Main content area
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Material Glass Tab Bar
                MaterialGlassTabBar(coordinator: coordinator)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
        }
        .environmentObject(coordinator)
        .sheet(item: $coordinator.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .fullScreenCover(item: $coordinator.presentedFullScreenCover) { cover in
            fullScreenCoverView(for: cover)
        }
        .alert(item: $coordinator.presentedAlert) { alert in
            alertView(for: alert)
        }
        .overlay(alignment: .top) {
            // Toast notifications
            if let toast = coordinator.presentedToast {
                GlassToast(
                    message: toast.message,
                    type: toast.type,
                    duration: toast.duration,
                    isDismissible: toast.isDismissible,
                    onDismiss: {
                        coordinator.dismissToast()
                    }
                )
                .padding(.horizontal, UISpacing.md)
                .padding(.top, UISpacing.md)
                .transition(MaterialMotion.Transition.slideDown)
                .zIndex(1000)
            }
        }
        .overlay {
            // Modal presentations
            if let modal = coordinator.presentedModal {
                modalView(for: modal)
                    .transition(MaterialMotion.Transition.scaleAndFade)
                    .zIndex(999)
            }
        }
    }
    
    // MARK: - Destination Views
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .profile(let userId):
            ProfileView()
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
            
        case .postDetail(let postId):
            PostDetailView()
                .navigationTitle("Post")
                .navigationBarTitleDisplayMode(.inline)
            
        case .searchResults(let query):
            SearchView()
                .navigationTitle("Search Results")
                .navigationBarTitleDisplayMode(.inline)
            
        case .settings:
            SettingsView()
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
            
        case .editProfile:
            ProfileView() // Placeholder - would be EditProfileView
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
            
        case .createPost:
            CreatePostView()
                .navigationTitle("Create Post")
                .navigationBarTitleDisplayMode(.inline)
            
        case .notifications:
            NotificationsView()
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.large)
            
        case .topics:
            TopicsView()
                .navigationTitle("Topics")
                .navigationBarTitleDisplayMode(.large)
            
        case .moderation:
            ModerationQueueView()
                .navigationTitle("Moderation")
                .navigationBarTitleDisplayMode(.large)
            
        case .invite:
            InviteView()
                .navigationTitle("Invite Friends")
                .navigationBarTitleDisplayMode(.inline)
            
        case .lookup:
            LookupWizardView()
                .navigationTitle("Lookup")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func sheetView(for sheet: SheetDestination) -> some View {
        switch sheet {
        case .filters:
            FilterSheetView()
            
        case .sortOptions:
            SortOptionsSheetView()
            
        case .sharePost(let postId):
            SharePostSheetView(postId: postId)
            
        case .userList(let type):
            UserListSheetView(type: type)
        }
    }
    
    @ViewBuilder
    private func fullScreenCoverView(for cover: FullScreenDestination) -> some View {
        switch cover {
        case .onboarding:
            OnboardingView()
            
        case .camera:
            CameraView()
            
        case .videoPlayer(let videoURL):
            VideoPlayerView(videoURL: videoURL)
        }
    }
    
    private func alertView(for alert: AlertDestination) -> Alert {
        if let primaryButton = alert.primaryButton,
           let secondaryButton = alert.secondaryButton {
            return Alert(
                title: Text(alert.title),
                message: alert.message.map(Text.init),
                primaryButton: alertButton(for: primaryButton),
                secondaryButton: alertButton(for: secondaryButton)
            )
        } else if let primaryButton = alert.primaryButton {
            return Alert(
                title: Text(alert.title),
                message: alert.message.map(Text.init),
                dismissButton: alertButton(for: primaryButton)
            )
        } else {
            return Alert(
                title: Text(alert.title),
                message: alert.message.map(Text.init)
            )
        }
    }
    
    private func alertButton(for button: AlertDestination.AlertButton) -> Alert.Button {
        switch button.style {
        case .default:
            return .default(Text(button.title)) {
                button.action?()
            }
        case .cancel:
            return .cancel(Text(button.title)) {
                button.action?()
            }
        case .destructive:
            return .destructive(Text(button.title)) {
                button.action?()
            }
        }
    }
    
    @ViewBuilder
    private func modalView(for modal: ModalDestination) -> some View {
        switch modal {
        case .createPost:
            GlassModal(isPresented: .constant(true)) {
                CreatePostView()
            }
            
        case .editProfile:
            GlassModal(isPresented: .constant(true)) {
                ProfileView() // Placeholder - would be EditProfileView
            }
            
        case .settings:
            GlassModal(isPresented: .constant(true)) {
                SettingsView()
            }
            
        case .imageViewer(let imageURL):
            ImageViewerModal(imageURL: imageURL)
            
        case .reportContent(let contentId):
            ReportContentModal(contentId: contentId)
        }
    }
}

// MARK: - Placeholder Views for Sheet Destinations

private struct FilterSheetView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Filter Options")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SortOptionsSheetView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Sort Options")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .navigationTitle("Sort")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SharePostSheetView: View {
    let postId: String
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Share Post: \(postId)")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct UserListSheetView: View {
    let type: SheetDestination.UserListType
    
    var body: some View {
        NavigationView {
            VStack {
                Text("\(type.rawValue.capitalized) List")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .navigationTitle(type.rawValue.capitalized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Placeholder Views for Modal Destinations

private struct ImageViewerModal: View {
    let imageURL: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("Image Viewer")
                    .foregroundColor(.white)
                    .font(.title2)
                Text(imageURL)
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
}

private struct ReportContentModal: View {
    let contentId: String
    
    var body: some View {
        GlassModal(isPresented: .constant(true)) {
            VStack(spacing: UISpacing.md) {
                Text("Report Content")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Content ID: \(contentId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                GlassButton("Submit Report") {
                    // Handle report submission
                }
            }
            .padding()
        }
    }
}

// MARK: - Placeholder Views for Full Screen Covers

private struct CameraView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("Camera View")
                    .foregroundColor(.white)
                    .font(.title)
                
                Spacer()
                
                Button("Close") {
                    NavigationCoordinator.shared.dismissFullScreenCover()
                }
                .foregroundColor(.white)
                .padding()
            }
        }
    }
}

private struct VideoPlayerView: View {
    let videoURL: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("Video Player")
                    .foregroundColor(.white)
                    .font(.title)
                
                Text(videoURL)
                    .foregroundColor(.gray)
                    .font(.caption)
                
                Spacer()
                
                Button("Close") {
                    NavigationCoordinator.shared.dismissFullScreenCover()
                }
                .foregroundColor(.white)
                .padding()
            }
        }
    }
}

// MARK: - Placeholder Views for Navigation Destinations
// PostDetailView is defined in Features/Feed/Views/PostDetailView.swift