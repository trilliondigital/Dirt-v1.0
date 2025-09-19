import SwiftUI

struct ProfileView: View {
    @State private var selectedTab = 0
    @State private var isSettingsPresented = false
    @AppStorage("moderationBackendEnabled") private var moderationBackendEnabled = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Material Glass overlay
                    ZStack(alignment: .bottomTrailing) {
                        // Cover Photo with glass overlay
                        Rectangle()
                            .fill(UIGradients.primary)
                            .frame(height: 160)
                            .overlay(
                                // Glass overlay for better text readability
                                Rectangle()
                                    .fill(MaterialDesignSystem.Glass.thin)
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            Text("Dirt")
                                                .font(.largeTitle)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .shadow(color: MaterialDesignSystem.GlassShadows.strong, radius: 8)
                                            Text("@dirtapp")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.9))
                                                .padding(.bottom, UISpacing.xs)
                                        }
                                    )
                            )
                        
                        // Profile Image with glass effect
                        ZStack {
                            Circle()
                                .fill(MaterialDesignSystem.Glass.regular)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .stroke(MaterialDesignSystem.GlassBorders.prominent, lineWidth: 2)
                                )
                                .shadow(color: MaterialDesignSystem.GlassShadows.medium, radius: 12, x: 0, y: 6)
                                .offset(y: 20)
                            
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(UIColors.secondaryLabel)
                                .offset(y: 20)
                        }
                        .offset(x: 20, y: 40)
                    }
                    .padding(.bottom, 40)
                    
                    // Stats with glass card
                    GlassCard(material: MaterialDesignSystem.Context.card, padding: UISpacing.md) {
                        HStack {
                            VStack {
                                Text("1,234")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(UIColors.label)
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundColor(UIColors.secondaryLabel)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Rectangle()
                                .fill(MaterialDesignSystem.GlassBorders.subtle)
                                .frame(width: 1, height: 30)
                            
                            VStack {
                                Text("5.6K")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(UIColors.label)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(UIColors.secondaryLabel)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Rectangle()
                                .fill(MaterialDesignSystem.GlassBorders.subtle)
                                .frame(width: 1, height: 30)
                            
                            VStack {
                                Text("2.1K")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(UIColors.label)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(UIColors.secondaryLabel)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Bio with glass card
                    GlassCard(material: MaterialDesignSystem.Context.card, padding: UISpacing.md) {
                        VStack(alignment: .leading, spacing: UISpacing.sm) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(UIColors.label)
                            
                            Text("Welcome to Dirt - the app where men can share their dating experiences, warn others about red flags, and celebrate green flags. Stay safe out there! 🚩✅")
                                .font(.subheadline)
                                .foregroundColor(UIColors.secondaryLabel)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .padding(.top, UISpacing.xs)
                    .glassAppear()
                    
                    // Tabs with glass styling
                    GlassCard(material: MaterialDesignSystem.Glass.ultraThin, padding: UISpacing.xs) {
                        HStack(spacing: 0) {
                            ForEach(Array(zip(["Posts", "Saved", "Liked"], [0, 1, 2])), id: \.1) { title, index in
                                Button(action: { 
                                    withAnimation(MaterialMotion.Interactive.tabSelection()) {
                                        selectedTab = index
                                    }
                                }) {
                                    VStack(spacing: UISpacing.xxs) {
                                        Text(title)
                                            .font(.subheadline)
                                            .fontWeight(selectedTab == index ? .semibold : .regular)
                                            .foregroundColor(selectedTab == index ? UIColors.accentPrimary : UIColors.secondaryLabel)
                                        
                                        Capsule()
                                            .fill(selectedTab == index ? UIColors.accentPrimary : Color.clear)
                                            .frame(height: 2)
                                            .padding(.horizontal, UISpacing.lg)
                                    }
                                    .padding(.vertical, UISpacing.sm)
                                }
                                .frame(maxWidth: .infinity)
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, UISpacing.lg)
                    
                    // Content based on tab
                    if selectedTab == 0 {
                        // Posts Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 1),
                            GridItem(.flexible(), spacing: 1),
                            GridItem(.flexible(), spacing: 1)
                        ], spacing: 1) {
                            ForEach(0..<15) { index in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .padding(.top, 4)
                    } else if selectedTab == 1 {
                        // Saved Posts
                        VStack(spacing: 20) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 60)
                            
                            Text("No saved posts yet")
                                .font(.headline)
                            
                            Text("Tap the bookmark icon on any post to save it here.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        // Liked Posts
                        VStack(spacing: 20) {
                            Image(systemName: "hand.thumbsup")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 60)
                            
                            Text("No liked posts yet")
                                .font(.headline)
                            
                            Text("Posts you like will appear here.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .background(MaterialDesignSystem.Context.navigation.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    GlassButton(
                        "",
                        systemImage: "gearshape",
                        style: .subtle
                    ) {
                        isSettingsPresented = true
                    }
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                NavigationView {
                    List {
                        Section(header: Text("Account")) {
                            NavigationLink(destination: Text("Edit Profile")) {
                                Label("Edit Profile", systemImage: "person")
                            }
                            
                            NavigationLink(destination: Text("Privacy")) {
                                Label("Privacy", systemImage: "lock")
                            }
                            
                            NavigationLink(destination: Text("Blocked Users")) {
                                Label("Blocked Users", systemImage: "person.slash")
                            }
                        }
                        
                        Section(header: Text("App Settings")) {
                            Toggle(isOn: .constant(true)) {
                                Label("Dark Mode", systemImage: "moon")
                            }
                            
                            Toggle(isOn: .constant(true)) {
                                Label("Push Notifications", systemImage: "bell")
                            }
                            
                            Toggle(isOn: Binding(
                                get: { moderationBackendEnabled },
                                set: { newValue in
                                    moderationBackendEnabled = newValue
                                    ReportService.backendEnabled = newValue
                                }
                            )) {
                                Label("Moderation Backend", systemImage: "shield.lefthalf.filled")
                            }
                            
                            NavigationLink(destination: ModerationQueueView()
                                .navigationTitle("Moderation Queue")) {
                                Label("Open Moderation Queue", systemImage: "tray.full")
                            }
                            
                            NavigationLink(destination: Text("Help & Support")) {
                                Label("Help & Support", systemImage: "questionmark.circle")
                            }
                        }
                        
                        Section {
                            Button(action: {
                                // Sign out action
                            }) {
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        
                        Section {
                            Text("Version 1.0.0")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .navigationTitle("Settings")
                    .navigationBarItems(trailing: Button("Done") {
                        isSettingsPresented = false
                    })
                }
            }
            .onAppear { ReportService.backendEnabled = moderationBackendEnabled }
        }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
