import SwiftUI

struct FilterSheet: View {
    @Binding var selectedFilter: FeedFilter
    @Binding var selectedCategory: PostCategory?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sort Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sort By")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(FeedFilter.allCases, id: \.self) { filter in
                        FilterOptionRow(
                            icon: filter.iconName,
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                            }
                        )
                    }
                }
                .padding(.vertical)
                
                Divider()
                
                // Category Filter
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Category")
                            .font(.headline)
                        
                        Spacer()
                        
                        if selectedCategory != nil {
                            Button("Clear") {
                                selectedCategory = nil
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(PostCategory.allCases, id: \.self) { category in
                                CategoryFilterCard(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                Spacer()
            }
            .navigationTitle("Filter Posts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct FilterOptionRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct CategoryFilterCard: View {
    let category: PostCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FilterSheet(
        selectedFilter: .constant(.latest),
        selectedCategory: .constant(.advice)
    )
}