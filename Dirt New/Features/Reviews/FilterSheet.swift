import SwiftUI

struct FilterSheet: View {
    let currentFilter: ContentFilter
    let onApply: (ContentFilter) -> Void
    
    @State private var tempFilter: ContentFilter
    @Environment(\.dismiss) private var dismiss
    
    init(currentFilter: ContentFilter, onApply: @escaping (ContentFilter) -> Void) {
        self.currentFilter = currentFilter
        self.onApply = onApply
        self._tempFilter = State(initialValue: currentFilter)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Sort Options
                    FilterSection(title: "Sort By") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                SortOptionCard(
                                    option: option,
                                    isSelected: tempFilter.sortBy == option
                                ) {
                                    tempFilter.sortBy = option
                                }
                            }
                        }
                    }
                    
                    // Categories
                    FilterSection(title: "Categories") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(ReviewCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: tempFilter.categories.contains(category)
                                ) {
                                    if tempFilter.categories.contains(category) {
                                        tempFilter.categories.remove(category)
                                    } else {
                                        tempFilter.categories.insert(category)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Rating Range
                    FilterSection(title: "Minimum Rating") {
                        RatingSlider(
                            value: Binding(
                                get: { tempFilter.ratingRange.lowerBound },
                                set: { newValue in
                                    tempFilter.ratingRange = newValue...tempFilter.ratingRange.upperBound
                                }
                            )
                        )
                    }
                    
                    // Date Range
                    FilterSection(title: "Date Range") {
                        VStack(spacing: 12) {
                            DateRangeOption(
                                title: "Any Time",
                                isSelected: tempFilter.dateRange == nil
                            ) {
                                tempFilter.dateRange = nil
                            }
                            
                            DateRangeOption(
                                title: "Last Week",
                                isSelected: tempFilter.dateRange?.start == DateRange.lastWeek.start
                            ) {
                                tempFilter.dateRange = DateRange.lastWeek
                            }
                            
                            DateRangeOption(
                                title: "Last Month",
                                isSelected: tempFilter.dateRange?.start == DateRange.lastMonth.start
                            ) {
                                tempFilter.dateRange = DateRange.lastMonth
                            }
                            
                            DateRangeOption(
                                title: "Last Year",
                                isSelected: tempFilter.dateRange?.start == DateRange.lastYear.start
                            ) {
                                tempFilter.dateRange = DateRange.lastYear
                            }
                        }
                    }
                    
                    // Location Filter
                    FilterSection(title: "Location") {
                        TextField("Enter location", text: Binding(
                            get: { tempFilter.location ?? "" },
                            set: { tempFilter.location = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.done)
                    }
                }
                .padding()
            }
            .navigationTitle("Filter Reviews")
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .trailing) {
                    HStack {
                        if tempFilter.isActive {
                            Button("Clear") {
                                tempFilter = ContentFilter()
                            }
                            .foregroundColor(.red)
                        }
                        
                        Button("Apply") {
                            onApply(tempFilter)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SortOptionCard: View {
    let option: SortOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: option.systemImage)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(option.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryChip: View {
    let category: ReviewCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.systemImage)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RatingSlider: View {
    @Binding var value: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(1...5, id: \.self) { rating in
                    Image(systemName: Double(rating) <= value ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }
                
                Spacer()
                
                Text("\(value, specifier: "%.1f")+")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Slider(value: $value, in: 1.0...5.0, step: 0.5)
                .accentColor(.yellow)
        }
    }
}

struct DateRangeOption: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FilterSheet(
        currentFilter: ContentFilter(),
        onApply: { _ in }
    )
}