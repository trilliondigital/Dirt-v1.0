import SwiftUI

struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var postText: String = ""
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var selectedTags: Set<String> = []
    @State private var isAnonymous = false
    @State private var selectedFlag: FlagCategory? = nil
    
    private let maxCharacters: Int = 500
    
    enum FlagCategory: String, CaseIterable, Identifiable {
        case red = "Red Flag"
        case green = "Green Flag"
        var id: String { rawValue }
    }
    
    let tagOptions = [
        "🚩 Red Flag", "✅ Green Flag", "👻 Ghosting", 
        "💬 Great Conversation", "💑 Second Date", "❌ Avoid"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Text Editor
                TextEditor(text: $postText)
                    .padding()
                    .frame(height: 150)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding()
                    .overlay(
                        postText.isEmpty ? 
                            Text("Share your experience...")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.top, 24)
                                .padding(.leading, 24)
                                .allowsHitTesting(false) : nil,
                        alignment: .topLeading
                    )
                    .onChange(of: postText) { _, newValue in
                        if newValue.count > maxCharacters {
                            postText = String(newValue.prefix(maxCharacters))
                        }
                    }
                
                // Character Counter
                HStack {
                    Spacer()
                    Text("\(postText.count)/\(maxCharacters)")
                        .font(.caption)
                        .foregroundColor(postText.count > maxCharacters - 20 ? .red : .secondary)
                        .padding(.trailing)
                }
                .padding(.bottom, 4)
                
                // Required Flag Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Flag")
                        .font(.headline)
                        .padding(.horizontal)
                    HStack(spacing: 12) {
                        ForEach(FlagCategory.allCases) { flag in
                            Button(action: {
                                selectedFlag = flag
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: flag == .red ? "flag.fill" : "checkmark.seal.fill")
                                    Text(flag.rawValue)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    (selectedFlag == flag ? (flag == .red ? Color.red.opacity(0.15) : Color.green.opacity(0.15)) : Color.gray.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedFlag == flag ? (flag == .red ? Color.red.opacity(0.5) : Color.green.opacity(0.5)) : Color.clear, lineWidth: 1)
                                )
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // Selected Image Preview
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .overlay(
                            Button(action: {
                                self.selectedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.7)))
                            }
                            .padding(8),
                            alignment: .topTrailing
                        )
                }
                
                // Tag Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Tags")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(tagOptions, id: \.self) { tag in
                                Button(action: {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }) {
                                    Text(tag)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedTags.contains(tag) ? 
                                                (tag.contains("🚩") || tag.contains("❌") ? 
                                                    Color.red.opacity(0.2) : 
                                                    Color.green.opacity(0.2)) : 
                                                Color.gray.opacity(0.1)
                                        )
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(
                                                    selectedTags.contains(tag) ? 
                                                        (tag.contains("🚩") || tag.contains("❌") ? 
                                                            Color.red.opacity(0.5) : 
                                                            Color.green.opacity(0.5)) : 
                                                        Color.clear,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                // Anonymous Toggle
                Toggle(isOn: $isAnonymous) {
                    HStack {
                        Image(systemName: "theatermasks")
                            .foregroundColor(.purple)
                        Text("Post Anonymously")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Photo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Post action
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Post")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canPost ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!canPost)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
            .navigationBarTitle("New Post", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $isImagePickerPresented) {
                // In a real app, you would use PHPickerViewController or UIImagePickerController
                // For this demo, we'll just simulate image selection
                Button("Select Image") {
                    // Simulate image selection
                    self.selectedImage = UIImage(systemName: "photo")
                    isImagePickerPresented = false
                }
                .padding()
            }
        }
    }
    
    private var canPost: Bool {
        let trimmed = postText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxCharacters && selectedFlag != nil
    }
}

// MARK: - Preview
struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}
