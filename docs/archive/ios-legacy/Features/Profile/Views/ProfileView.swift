import SwiftUI

struct ProfileView: View {
    @State private var selectedTab = 0
    @State private var isSettingsPresented = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    ZStack(alignment: .bottomTrailing) {
                        // Cover Photo
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), 
                                              startPoint: .topLeading, 
                                              endPoint: .bottomTrailing))
                            .frame(height: 160)
                            .overlay(
                                VStack {
                                    Spacer()
                                    Text("Dirt")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .shadow(radius: 5)
                                    Text("@dirtapp")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.bottom, 8)
                                }
                            )
                        
                        // Profile Image
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .shadow(radius: 5)
                                .offset(y: 20)
                            
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                                .offset(y: 20)
                        }
                        .offset(x: 20, y: 40)
                    }
                    .padding(.bottom, 40)
                    
                    // Stats
                    HStack {
                        VStack {
                            Text("1,234")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Posts")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 30)
                        
                        VStack {
                            Text("5.6K")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Followers")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 30)
                        
                        VStack {
                            Text("2.1K")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Following")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 20)
                    
                    // Bio
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)
                        
                        Text("Welcome to Dirt - the app where men can share their dating experiences, warn others about red flags, and celebrate green flags. Stay safe out there! 🚩✅")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Tabs
                    HStack(spacing: 0) {
                        Button(action: { selectedTab = 0 }) {
                            VStack {
                                Text("Posts")
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == 0 ? .semibold : .regular)
                                    .foregroundColor(selectedTab == 0 ? .blue : .gray)
                                
                                Capsule()
                                    .fill(selectedTab == 0 ? Color.blue : Color.clear)
                                    .frame(height: 2)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button(action: { selectedTab = 1 }) {
                            VStack {
                                Text("Saved")
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == 1 ? .semibold : .regular)
                                    .foregroundColor(selectedTab == 1 ? .blue : .gray)
                                
                                Capsule()
                                    .fill(selectedTab == 1 ? Color.blue : Color.clear)
                                    .frame(height: 2)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button(action: { selectedTab = 2 }) {
                            VStack {
                                Text("Liked")
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == 2 ? .semibold : .regular)
                                    .foregroundColor(selectedTab == 2 ? .blue : .gray)
                                
                                Capsule()
                                    .fill(selectedTab == 2 ? Color.blue : Color.clear)
                                    .frame(height: 2)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSettingsPresented = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
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
        }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
