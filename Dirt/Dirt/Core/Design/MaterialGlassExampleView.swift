import SwiftUI

/// Example view demonstrating all Material Glass components
/// This view serves as both documentation and a test harness for the components
struct MaterialGlassExampleView: View {
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var isModalPresented = false
    @State private var showToast = false
    @State private var toastType: GlassToast.ToastType = .info
    
    var body: some View {
        VStack(spacing: 0) {
            // Glass Navigation Bar
            GlassNavigationBar(
                title: "Material Glass Demo",
                leading: {
                    GlassButton("Back", systemImage: "chevron.left", style: .subtle) {
                        // Handle back action
                    }
                },
                trailing: {
                    GlassButton("Settings", systemImage: "gear", style: .subtle) {
                        // Handle settings action
                    }
                }
            )
            
            ScrollView {
                VStack(spacing: 24) {
                    // Search Bar Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search Bar")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        GlassSearchBar(
                            text: $searchText,
                            placeholder: "Search for anything..."
                        ) {
                            showToast(message: "Search performed for: \(searchText)", type: .info)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Button Styles Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Button Styles")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                GlassButton("Primary", style: .primary) {
                                    showToast(message: "Primary button tapped", type: .success)
                                }
                                
                                GlassButton("Secondary", style: .secondary) {
                                    showToast(message: "Secondary button tapped", type: .info)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                GlassButton("Destructive", style: .destructive) {
                                    showToast(message: "Destructive action", type: .error)
                                }
                                
                                GlassButton("Subtle", style: .subtle) {
                                    showToast(message: "Subtle action", type: .info)
                                }
                            }
                            
                            GlassButton("With Icon", systemImage: "star.fill", style: .primary) {
                                showToast(message: "Icon button tapped", type: .success)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Glass Cards Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Glass Cards")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Basic Glass Card")
                                        .font(.headline)
                                    Text("This is a basic glass card with default styling. It uses thin material for subtle transparency.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            GlassCard(material: .regularMaterial, cornerRadius: 20) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Custom Glass Card")
                                        .font(.headline)
                                    Text("This card uses regular material and custom corner radius for a more prominent appearance.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        GlassButton("Action 1", style: .secondary) {
                                            showToast(message: "Card action 1", type: .info)
                                        }
                                        
                                        GlassButton("Action 2", style: .primary) {
                                            showToast(message: "Card action 2", type: .success)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Modal Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Modal")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        GlassButton("Show Modal", systemImage: "plus.circle", style: .primary) {
                            isModalPresented = true
                        }
                        .padding(.horizontal)
                    }
                    
                    // Toast Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Toast Notifications")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                GlassButton("Success", style: .secondary) {
                                    showToast(message: "Operation completed successfully!", type: .success)
                                }
                                
                                GlassButton("Warning", style: .secondary) {
                                    showToast(message: "Please check your input", type: .warning)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                GlassButton("Error", style: .secondary) {
                                    showToast(message: "Something went wrong", type: .error)
                                }
                                
                                GlassButton("Info", style: .secondary) {
                                    showToast(message: "Here's some information", type: .info)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100) // Space for tab bar
                }
                .padding(.vertical)
            }
            
            // Glass Tab Bar
            GlassTabBar(
                selectedTab: $selectedTab,
                tabs: [
                    GlassTabBar.TabItem(title: "Home", systemImage: "house", selectedSystemImage: "house.fill"),
                    GlassTabBar.TabItem(title: "Search", systemImage: "magnifyingglass"),
                    GlassTabBar.TabItem(title: "Create", systemImage: "plus.circle", selectedSystemImage: "plus.circle.fill"),
                    GlassTabBar.TabItem(title: "Profile", systemImage: "person", selectedSystemImage: "person.fill")
                ]
            )
        }
        .overlay(
            // Toast overlay
            VStack {
                Spacer()
                if showToast {
                    GlassToast(message: getToastMessage(), type: toastType)
                        .padding()
                        .transition(MaterialMotion.Transition.slideDown)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    self.showToast = false
                                }
                            }
                        }
                }
                Spacer()
                Spacer() // Extra space to position above tab bar
            }
        )
        .sheet(isPresented: $isModalPresented) {
            // Modal content using GlassModal
            ZStack {
                Color.clear
                    .ignoresSafeArea()
                
                GlassModal(isPresented: $isModalPresented) {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Example Modal")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                            GlassButton("Close", systemImage: "xmark", style: .subtle) {
                                isModalPresented = false
                            }
                        }
                        
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Modal Content")
                                    .font(.headline)
                                Text("This is an example of a glass modal with nested glass components. The modal uses thick material for prominence.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        GlassSearchBar(
                            text: .constant(""),
                            placeholder: "Search within modal..."
                        )
                        
                        HStack {
                            GlassButton("Cancel", style: .secondary) {
                                isModalPresented = false
                            }
                            
                            Spacer()
                            
                            GlassButton("Save", style: .primary) {
                                showToast(message: "Changes saved!", type: .success)
                                isModalPresented = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showToast(message: String, type: GlassToast.ToastType) {
        toastType = type
        withAnimation(MaterialMotion.Glass.toastAppear) {
            showToast = true
        }
    }
    
    private func getToastMessage() -> String {
        switch toastType {
        case .success: return "Operation completed successfully!"
        case .warning: return "Please check your input"
        case .error: return "Something went wrong"
        case .info: return "Here's some information"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MaterialGlassExampleView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialGlassExampleView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        
        MaterialGlassExampleView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
#endif