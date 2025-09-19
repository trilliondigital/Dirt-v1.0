import SwiftUI

struct FeedView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ColorPalette.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category filter bar
                    CategoryFilterBar(
                        selectedCategory: $viewModel.selectedCategory,
                        categories: PostCategory.allCases
                    )
                    
                    // Feed content
                    FeedContent(viewModel: viewModel)
                }
                
                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            // Navigate to create post
                        }
                        .padding(.trailing, DesignTokens.Spacing.lg)
                        .padding(.bottom, DesignTokens.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadInitialPosts()
        }
    }
}

// MARK: - Feed Content
struct FeedContent: View {
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(viewModel.posts) { post in
                    PostCard(post: post)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .onAppear {
                            // Load more posts when approaching end
                            if post.id == viewModel.posts.last?.id {
                                Task {
                                    await viewModel.loadMorePosts()
                                }
                            }
                        }
                }
                
                // Loading indicator for infinite scroll
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        LoadingSpinner(size: .medium)
                        Spacer()
                    }
                    .padding(.vertical, DesignTokens.Spacing.lg)
                }
                
                // Empty state
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    FeedEmptyState()
                        .padding(.top, DesignTokens.Spacing.xxl)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .refreshable {
            await viewModel.refreshPosts()
        }
        .overlay {
            // Initial loading state
            if viewModel.isLoading && viewModel.posts.isEmpty {
                FeedLoadingState()
            }
        }
    }
}

// MARK: - Category Filter Bar
struct CategoryFilterBar: View {
    @Binding var selectedCategory: PostCategory?
    let categories: [PostCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // All categories button
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: {
                        HapticFeedback.filterSelection()
                        withAnimation(.easeInOut(duration: DesignTokens.Animation.standard)) {
                            selectedCategory = nil
                        }
                    }
                )
                
                // Individual category buttons
                ForEach(categories, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        icon: category.iconName,
                        isSelected: selectedCategory == category,
                        action: {
                            HapticFeedback.filterSelection()
                            withAnimation(.easeInOut(duration: DesignTokens.Animation.standard)) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(ColorPalette.backgroundPrimary)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(TypographyStyles.caption1)
                }
                
                Text(title)
                    .font(TypographyStyles.caption1)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                isSelected ? ColorPalette.accent : ColorPalette.surfaceSecondary
            )
            .foregroundColor(
                isSelected ? ColorPalette.backgroundPrimary : ColorPalette.textPrimary
            )
            .clipShape(Capsule())
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: DesignTokens.Animation.quick), value: isSelected)
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.buttonTap()
            action()
        }) {
            Image(systemName: "plus")
                .font(TypographyStyles.title2)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.backgroundPrimary)
                .frame(width: 56, height: 56)
                .background(ColorPalette.accent)
                .clipShape(Circle())
                .shadow(
                    color: ColorPalette.accent.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: DesignTokens.Animation.quick), value: true)
    }
}

// MARK: - Loading State
struct FeedLoadingState: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                PostCardSkeleton()
                    .padding(.horizontal, DesignTokens.Spacing.md)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}

struct PostCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // Header skeleton
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Circle()
                        .fill(ColorPalette.surfaceSecondary)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Rectangle()
                            .fill(ColorPalette.surfaceSecondary)
                            .frame(width: 100, height: 12)
                        
                        Rectangle()
                            .fill(ColorPalette.surfaceSecondary)
                            .frame(width: 60, height: 10)
                    }
                    
                    Spacer()
                }
                
                // Badges skeleton
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Rectangle()
                        .fill(ColorPalette.surfaceSecondary)
                        .frame(width: 80, height: 24)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(ColorPalette.surfaceSecondary)
                        .frame(width: 70, height: 24)
                        .clipShape(Capsule())
                }
                
                // Content skeleton
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Rectangle()
                        .fill(ColorPalette.surfaceSecondary)
                        .frame(height: 16)
                    
                    Rectangle()
                        .fill(ColorPalette.surfaceSecondary)
                        .frame(height: 14)
                    
                    Rectangle()
                        .fill(ColorPalette.surfaceSecondary)
                        .frame(width: 200, height: 14)
                }
                
                // Engagement bar skeleton
                HStack(spacing: DesignTokens.Spacing.lg) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(ColorPalette.surfaceSecondary)
                            .frame(width: 40, height: 16)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(ColorPalette.surfaceSecondary)
                        .frame(width: 20, height: 16)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(
            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Empty State
struct FeedEmptyState: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(ColorPalette.textTertiary)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("No posts yet")
                    .font(TypographyStyles.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.text.primary)
                
                Text("Be the first to share your dating experience with the community!")
                    .font(TypographyStyles.body)
                    .foregroundColor(ColorPalette.text.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ActionButton(
                title: "Create First Post",
                style: .primary,
                size: .medium,
                action: {
                    // Navigate to create post
                }
            )
        }
        .padding(DesignTokens.Spacing.xl)
    }
}

