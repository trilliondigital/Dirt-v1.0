import SwiftUI

// MARK: - Navigation Router
/// Handles routing logic and view creation for the navigation system
struct NavigationRouter {
    
    // MARK: - Main Tab Content
    
    /// Get the main content view for a specific tab
    @ViewBuilder
    static func mainContent(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            FeedView()
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.large)
            
        case .search:
            SearchView()
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.large)
            
        case .create:
            CreatePostView()
                .navigationTitle("Create")
                .navigationBarTitleDisplayMode(.inline)
            
        case .notifications:
            NotificationsView()
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.large)
            
        case .profile:
            ProfileView()
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Tab Content Container
    
    /// Container that manages tab switching with Material Glass animations
    struct TabContentContainer: View {
        @ObservedObject var coordinator: NavigationCoordinator
        
        var body: some View {
            TabView(selection: $coordinator.selectedTab) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    NavigationStack(path: $coordinator.navigationPath) {
                        mainContent(for: tab)
                            .navigationDestination(for: NavigationDestination.self) { destination in
                                destinationView(for: destination)
                            }
                    }
                    .tag(tab)
                    .tabItem {
                        EmptyView() // We use custom tab bar
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(MaterialMotion.Glass.navigationTransition, value: coordinator.selectedTab)
        }
        
        @ViewBuilder
        private func destinationView(for destination: NavigationDestination) -> some View {
            switch destination {
            case .profile(let userId):
                ProfileView()
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.large)
                
            case .postDetail(let postId):
                PostDetailView(postId: postId)
                    .navigationTitle("Post")
                    .navigationBarTitleDisplayMode(.inline)
                
            case .searchResults(let query):
                SearchResultsView(query: query)
                    .navigationTitle("Search Results")
                    .navigationBarTitleDisplayMode(.inline)
                
            case .settings:
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
                
            case .editProfile:
                EditProfileView()
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
    }
}

// MARK: - Enhanced Destination Views

/// Enhanced Post Detail View with Material Glass styling
private struct PostDetailView: View {
    let postId: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UISpacing.md) {
                GlassCard {
                    VStack(alignment: .leading, spacing: UISpacing.sm) {
                        Text("Post Detail")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Post ID: \(postId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("This is a placeholder for the post detail view with Material Glass styling.")
                            .foregroundColor(.secondary)
                    }
                }
                
                GlassCard {
                    VStack(alignment: .leading, spacing: UISpacing.sm) {
                        Text("Comments")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(0..<3) { index in
                            VStack(alignment: .leading, spacing: UISpacing.xs) {
                                Text("Comment \(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("This is a sample comment with Material Glass styling.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, UISpacing.xs)
                            
                            if index < 2 {
                                Divider()
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100) // Account for tab bar
            }
            .padding()
        }
        .background(UIColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                GlassButton("Share", systemImage: "square.and.arrow.up", style: .subtle) {
                    // Handle share action
                }
            }
        }
    }
}

/// Enhanced Search Results View
private struct SearchResultsView: View {
    let query: String
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: UISpacing.md) {
                // Search query display
                GlassCard {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        Text("Results for: \"\(query)\"")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                }
                
                // Sample search results
                ForEach(0..<10) { index in
                    GlassCard {
                        VStack(alignment: .leading, spacing: UISpacing.sm) {
                            Text("Search Result \(index + 1)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("This is a sample search result for query: \(query)")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("Relevance: \(Int.random(in: 70...100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                GlassButton("View", style: .subtle) {
                                    // Handle view action
                                }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100) // Account for tab bar
            }
            .padding()
        }
        .background(UIColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                GlassButton("Filter", systemImage: "line.3.horizontal.decrease.circle", style: .subtle) {
                    NavigationCoordinator.shared.presentSheet(.filters)
                }
            }
        }
    }
}

/// Enhanced Edit Profile View
private struct EditProfileView: View {
    @State private var displayName = ""
    @State private var bio = ""
    @State private var website = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: UISpacing.lg) {
                // Profile Image Section
                GlassCard {
                    VStack(spacing: UISpacing.md) {
                        Circle()
                            .fill(MaterialDesignSystem.GlassColors.neutral)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                            )
                        
                        GlassButton("Change Photo", systemImage: "camera", style: .secondary) {
                            NavigationCoordinator.shared.presentFullScreenCover(.camera)
                        }
                    }
                }
                
                // Profile Information Section
                GlassCard {
                    VStack(alignment: .leading, spacing: UISpacing.md) {
                        Text("Profile Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: UISpacing.sm) {
                            Text("Display Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Enter your display name", text: $displayName)
                                .textFieldStyle(GlassTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: UISpacing.sm) {
                            Text("Bio")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Tell us about yourself", text: $bio, axis: .vertical)
                                .textFieldStyle(GlassTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        VStack(alignment: .leading, spacing: UISpacing.sm) {
                            Text("Website")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("https://yourwebsite.com", text: $website)
                                .textFieldStyle(GlassTextFieldStyle())
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: UISpacing.md) {
                    GlassButton("Save Changes", systemImage: "checkmark.circle", style: .primary) {
                        // Handle save action
                        NavigationCoordinator.shared.pop()
                    }
                    
                    GlassButton("Cancel", style: .secondary) {
                        NavigationCoordinator.shared.pop()
                    }
                }
                
                Spacer(minLength: 100) // Account for tab bar
            }
            .padding()
        }
        .background(UIColors.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Glass Text Field Style

/// Custom text field style with Material Glass background
struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, UISpacing.md)
            .padding(.vertical, UISpacing.sm)
            .background(MaterialDesignSystem.Glass.ultraThin, in: RoundedRectangle(cornerRadius: UICornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: UICornerRadius.md)
                    .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
            )
    }
}

// MARK: - Navigation Environment

/// Environment key for navigation coordinator
struct NavigationCoordinatorKey: EnvironmentKey {
    static let defaultValue = NavigationCoordinator.shared
}

extension EnvironmentValues {
    var navigationCoordinator: NavigationCoordinator {
        get { self[NavigationCoordinatorKey.self] }
        set { self[NavigationCoordinatorKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Inject navigation coordinator into environment
    func withNavigationCoordinator(_ coordinator: NavigationCoordinator = NavigationCoordinator.shared) -> some View {
        environment(\.navigationCoordinator, coordinator)
    }
}