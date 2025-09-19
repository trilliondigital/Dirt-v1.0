import SwiftUI

// MARK: - Category Browsing View
struct CategoryBrowsingView: View {
    @StateObject private var viewModel = CategoryBrowsingViewModel()
    @State private var selectedCategory: PostCategory?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Category Grid
                    categoryGrid
                    
                    // Popular Categories
                    if !viewModel.popularCategories.isEmpty {
                        popularCategoriesSection
                    }
                    
                    // Recent Activity by Category
                    if !viewModel.categoryActivity.isEmpty {
                        recentActivitySection
                    }
                }
                .padding()
            }
            .navigationTitle("Browse Categories")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshData()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(item: $selectedCategory) { category in
                CategoryDetailView(category: category)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore by Category")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Discover content organized by topics and interests")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Category Grid
    private var categoryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(PostCategory.allCases, id: \.self) { category in
                CategoryCard(
                    category: category,
                    stats: viewModel.categoryStats[category],
                    onTap: {
                        selectedCategory = category
                    }
                )
            }
        }
    }
    
    // MARK: - Popular Categories Section
    private var popularCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Popular Categories")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.popularCategories, id: \.category) { categoryData in
                        PopularCategoryCard(
                            categoryData: categoryData,
                            onTap: {
                                selectedCategory = categoryData.category
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.categoryActivity.prefix(5), id: \.category) { activity in
                    CategoryActivityRow(
                        activity: activity,
                        onTap: {
                            selectedCategory = activity.category
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: PostCategory
    let stats: CategoryStats?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon and badge
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundColor(category.color)
                }
                
                // Category info
                VStack(spacing: 4) {
                    Text(category.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    if let stats = stats {
                        Text("\(stats.postCount) posts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Engagement indicator
                if let stats = stats, stats.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Popular Category Card
struct PopularCategoryCard: View {
    let categoryData: PopularCategoryData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: categoryData.category.iconName)
                        .foregroundColor(categoryData.category.color)
                    Spacer()
                    Text("+\(categoryData.growthPercentage)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Text(categoryData.category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(categoryData.recentPosts) new posts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 140, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryData.category.color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Activity Row
struct CategoryActivityRow: View {
    let activity: CategoryActivity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: activity.category.iconName)
                    .font(.title3)
                    .foregroundColor(activity.category.color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(activity.category.color.opacity(0.2))
                    )
                
                // Activity info
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.category.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(activity.newPosts) new posts in last 24h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Engagement indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(activity.totalEngagement)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("interactions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Detail View
struct CategoryDetailView: View {
    let category: PostCategory
    @StateObject private var viewModel = CategoryDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Category header
                    categoryHeader
                    
                    // Filter options
                    filterSection
                    
                    // Content list
                    contentList
                }
                .padding()
            }
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadContent(for: category)
            }
        }
    }
    
    private var categoryHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.largeTitle)
                .foregroundColor(category.color)
            
            Text(category.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let stats = viewModel.categoryStats {
                HStack(spacing: 20) {
                    StatItem(title: "Posts", value: "\(stats.postCount)")
                    StatItem(title: "Active", value: "\(stats.activeUsers)")
                    StatItem(title: "Today", value: "\(stats.todayPosts)")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(category.color.opacity(0.1))
        )
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ContentSortOption.allCases, id: \.self) { option in
                    FilterChip(
                        title: option.displayName,
                        isSelected: viewModel.selectedSort == option,
                        action: {
                            Task {
                                await viewModel.updateSort(option)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var contentList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.content, id: \.id) { content in
                CategoryContentCard(content: content)
            }
        }
    }
}

// MARK: - Supporting Views
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CategoryContentCard: View {
    let content: CategoryContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: content.type.iconName)
                    .foregroundColor(content.type.color)
                Text(content.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(content.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(content.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(content.preview)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label("\(content.upvotes)", systemImage: "arrow.up")
                Label("\(content.comments)", systemImage: "bubble.left")
                Spacer()
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Extensions
extension PostCategory {
    var color: Color {
        switch self {
        case .advice:
            return .blue
        case .experience:
            return .green
        case .question:
            return .orange
        case .strategy:
            return .purple
        case .success:
            return .yellow
        case .rant:
            return .red
        case .general:
            return .gray
        }
    }
}

enum ContentSortOption: String, CaseIterable {
    case recent = "Recent"
    case popular = "Popular"
    case trending = "Trending"
    case topRated = "Top Rated"
    
    var displayName: String {
        return rawValue
    }
}

#Preview {
    CategoryBrowsingView()
}