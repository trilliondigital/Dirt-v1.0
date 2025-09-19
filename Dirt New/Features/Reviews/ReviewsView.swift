import SwiftUI

struct ReviewsView: View {
    @StateObject private var viewModel = ReviewsViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with filter button
                HStack {
                    Text("Reviews")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content area
                if viewModel.isLoading && viewModel.reviews.isEmpty {
                    // Loading state
                    ReviewsLoadingView()
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state
                    ReviewsErrorView(errorMessage: errorMessage) {
                        Task {
                            await viewModel.loadReviews()
                        }
                    }
                } else if viewModel.reviews.isEmpty {
                    // Empty state
                    ReviewsEmptyView()
                } else {
                    // Reviews grid
                    ReviewsGridView(reviews: viewModel.filteredReviews)
                        .refreshable {
                            await viewModel.refreshReviews()
                        }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showingFilterSheet) {
                FilterSheet(
                    currentFilter: viewModel.currentFilter,
                    onApply: { filter in
                        viewModel.applyFilter(filter)
                    }
                )
            }
            .onAppear {
                Task {
                    await viewModel.loadReviews()
                }
            }
            .onReceive(appState.$deepLinkPath) { path in
                if let path = path, appState.selectedTab == .reviews {
                    handleDeepLink(path)
                }
            }
        }
    }
    
    private func handleDeepLink(_ path: String) {
        // Handle deep linking within reviews
        // This could navigate to specific review details, categories, etc.
        appState.deepLinkPath = nil // Clear after handling
    }
}

// MARK: - Supporting Views

struct ReviewsLoadingView: View {
    @State private var columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<6, id: \.self) { _ in
                        ReviewCardSkeleton()
                    }
                }
                .padding()
                .onAppear {
                    updateColumns(for: geometry.size)
                }
            }
        }
    }
    
    private func updateColumns(for size: CGSize) {
        let padding: CGFloat = 32
        let spacing: CGFloat = 16
        let minCardWidth: CGFloat = 160
        
        let availableWidth = size.width - padding
        let numberOfColumns = max(1, min(Int(availableWidth / (minCardWidth + spacing)), 3))
        
        columns = Array(repeating: GridItem(.flexible()), count: numberOfColumns)
    }
}

struct ReviewsErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Unable to load reviews")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ReviewsEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Reviews Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Be the first to share your dating experience!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Review") {
                // Navigate to create review
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ReviewsGridView: View {
    let reviews: [Review]
    @State private var columns: [GridItem] = []
    @State private var screenSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(reviews) { review in
                        ReviewCard(review: review)
                            .onTapGesture {
                                // Navigate to review detail
                            }
                    }
                }
                .padding()
                .onAppear {
                    updateGridLayout(for: geometry.size)
                }
                .onChange(of: geometry.size) { newSize in
                    if newSize != screenSize {
                        screenSize = newSize
                        updateGridLayout(for: newSize)
                    }
                }
            }
        }
    }
    
    private func updateGridLayout(for size: CGSize) {
        let padding: CGFloat = 32 // 16 on each side
        let spacing: CGFloat = 16
        let minCardWidth: CGFloat = 160
        let maxCardWidth: CGFloat = 200
        
        let availableWidth = size.width - padding
        let idealColumns = Int(availableWidth / (minCardWidth + spacing))
        let numberOfColumns = max(1, min(idealColumns, 3)) // Max 3 columns
        
        // Calculate actual card width to ensure good proportions
        let actualCardWidth = (availableWidth - CGFloat(numberOfColumns - 1) * spacing) / CGFloat(numberOfColumns)
        
        // Use flexible columns if card width is reasonable, otherwise use fixed width
        if actualCardWidth <= maxCardWidth {
            columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: numberOfColumns)
        } else {
            columns = Array(repeating: GridItem(.fixed(maxCardWidth), spacing: spacing), count: numberOfColumns)
        }
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Review image or placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.gray)
                )
            
            // Review content
            VStack(alignment: .leading, spacing: 4) {
                Text(review.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(review.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ReviewCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
                .shimmer(isAnimating: isAnimating)
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .shimmer(isAnimating: isAnimating)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shimmer(isAnimating: isAnimating)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(30))
                .offset(x: isAnimating ? 200 : -200)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                    value: isAnimating
                )
        )
        .clipped()
    }
}

#Preview {
    ReviewsView()
        .environmentObject(AppState())
}