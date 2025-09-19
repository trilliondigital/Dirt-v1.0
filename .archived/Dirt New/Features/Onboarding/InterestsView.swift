import SwiftUI

struct InterestsView: View {
    @Binding var selectedCategories: Set<PostCategory>
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("What interests you?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select topics you'd like to see in your feed. You can change these later.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(PostCategory.allCases, id: \.self) { category in
                        CategorySelectionCard(
                            category: category,
                            isSelected: selectedCategories.contains(category),
                            onTap: {
                                toggleCategory(category)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCategories.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(selectedCategories.isEmpty)
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func toggleCategory(_ category: PostCategory) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }
    }
}

struct CategorySelectionCard: View {
    let category: PostCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(category.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    InterestsView(
        selectedCategories: .constant([.advice, .experience]),
        onContinue: {}
    )
}