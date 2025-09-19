import SwiftUI

// MARK: - Tag Selector View
struct TagSelectorView: View {
    @Binding var selectedTags: Set<ReviewTag>
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private let maxTags = 10
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchSection
                
                // Selected Tags Summary
                if !selectedTags.isEmpty {
                    selectedTagsSection
                }
                
                // Tag Categories
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(TagCategory.allCases, id: \.self) { category in
                            TagCategorySection(
                                category: category,
                                selectedTags: $selectedTags,
                                searchText: searchText,
                                maxTags: maxTags
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search tags...")
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Selected: \(selectedTags.count)/\(maxTags)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !selectedTags.isEmpty {
                    Button("Clear All") {
                        selectedTags.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            
            if selectedTags.count >= maxTags {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Maximum tags selected")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Selected Tags Section
    
    private var selectedTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Tags")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(selectedTags), id: \.self) { tag in
                        SelectedTagChip(tag: tag) {
                            selectedTags.remove(tag)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Tag Category Section

struct TagCategorySection: View {
    let category: TagCategory
    @Binding var selectedTags: Set<ReviewTag>
    let searchText: String
    let maxTags: Int
    
    private var filteredTags: [ReviewTag] {
        let categoryTags = category.tags
        
        if searchText.isEmpty {
            return categoryTags
        } else {
            return categoryTags.filter { tag in
                tag.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        if !filteredTags.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Category Header
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    
                    Text(category.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                // Category Description
                if !category.description.isEmpty {
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Tags Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(filteredTags, id: \.self) { tag in
                        TagSelectionChip(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            isDisabled: !selectedTags.contains(tag) && selectedTags.count >= maxTags
                        ) {
                            toggleTag(tag)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func toggleTag(_ tag: ReviewTag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else if selectedTags.count < maxTags {
            selectedTags.insert(tag)
        }
    }
}

// MARK: - Tag Chips

struct TagSelectionChip: View {
    let tag: ReviewTag
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Tag indicator
                Circle()
                    .fill(tag.isPositive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(tag.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .foregroundColor(textColor)
        }
        .disabled(isDisabled)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color(.systemGray5)
        } else if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.blue
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var textColor: Color {
        if isDisabled {
            return Color(.systemGray3)
        } else {
            return Color.primary
        }
    }
}

struct SelectedTagChip: View {
    let tag: ReviewTag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.isPositive ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            
            Text(tag.displayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(16)
    }
}

// MARK: - Tag Categories

enum TagCategory: String, CaseIterable {
    case overall = "overall"
    case photos = "photos"
    case conversation = "conversation"
    case behavior = "behavior"
    case meetup = "meetup"
    
    var displayName: String {
        switch self {
        case .overall:
            return "Overall Experience"
        case .photos:
            return "Photos & Profile"
        case .conversation:
            return "Conversation Quality"
        case .behavior:
            return "Behavior & Attitude"
        case .meetup:
            return "Meeting & Dating"
        }
    }
    
    var description: String {
        switch self {
        case .overall:
            return "General impressions and flags"
        case .photos:
            return "Profile photos and accuracy"
        case .conversation:
            return "Communication style and quality"
        case .behavior:
            return "Personality and behavior traits"
        case .meetup:
            return "In-person meeting experiences"
        }
    }
    
    var icon: String {
        switch self {
        case .overall:
            return "flag.fill"
        case .photos:
            return "photo.fill"
        case .conversation:
            return "message.fill"
        case .behavior:
            return "person.fill"
        case .meetup:
            return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .overall:
            return .blue
        case .photos:
            return .purple
        case .conversation:
            return .green
        case .behavior:
            return .orange
        case .meetup:
            return .pink
        }
    }
    
    var tags: [ReviewTag] {
        switch self {
        case .overall:
            return [.redFlag, .greenFlag, .authentic, .catfish]
        case .photos:
            return [.misleadingPhotos, .accuratePhotos]
        case .conversation:
            return [.goodConversation, .poorConversation, .respectful, .disrespectful]
        case .behavior:
            return [.respectful, .disrespectful, .ghosted]
        case .meetup:
            return [.metInPerson, .longTermPotential, .hookupOnly]
        }
    }
}

// MARK: - Preview

struct TagSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        TagSelectorView(selectedTags: .constant([.greenFlag, .goodConversation]))
    }
}