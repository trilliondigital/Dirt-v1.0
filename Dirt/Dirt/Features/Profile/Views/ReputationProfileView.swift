import SwiftUI

// MARK: - Reputation Profile View
struct ReputationProfileView: View {
    @StateObject private var reputationService = ReputationService()
    @State private var userReputation: Int = 0
    @State private var achievements: [Achievement] = []
    @State private var reputationHistory: [ReputationEvent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    let userId: UUID
    let anonymousUsername: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                profileHeader
                
                // Reputation Overview
                reputationOverview
                
                // Achievements Section
                achievementsSection
                
                // Contribution History
                contributionHistory
                
                // Reputation Breakdown
                reputationBreakdown
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadProfileData()
        }
        .refreshable {
            await loadProfileData()
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Anonymous Avatar
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay {
                    Text(String(anonymousUsername.prefix(2)).uppercased())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 4) {
                Text(anonymousUsername)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Anonymous Member")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Reputation Overview
    
    private var reputationOverview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Reputation")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                reputationBadge
            }
            
            // Reputation Progress
            reputationProgress
            
            // Quick Stats
            HStack(spacing: 20) {
                statItem(title: "Total Points", value: "\(userReputation)")
                statItem(title: "Achievements", value: "\(achievements.count)")
                statItem(title: "Level", value: reputationLevel)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var reputationBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: reputationIcon)
                .foregroundColor(reputationColor)
            
            Text("\(userReputation)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(reputationColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(reputationColor.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var reputationProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress to \(nextLevelName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(pointsToNextLevel) points to go")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(userReputation % 100), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: reputationColor))
        }
    }
    
    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if achievements.count > 0 {
                    Text("\(achievements.count) earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if achievements.isEmpty {
                emptyAchievementsView
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(achievements) { achievement in
                        AchievementBadgeView(achievement: achievement)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var emptyAchievementsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No achievements yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Start contributing to earn your first achievement!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Contribution History
    
    private var contributionHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if reputationHistory.isEmpty {
                emptyHistoryView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(reputationHistory.prefix(5)) { event in
                        ReputationEventRow(event: event)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No activity yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Your contributions will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Reputation Breakdown
    
    private var reputationBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reputation Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                breakdownRow(title: "Posts", points: postPoints, icon: "doc.text")
                breakdownRow(title: "Reviews", points: reviewPoints, icon: "star")
                breakdownRow(title: "Comments", points: commentPoints, icon: "bubble.left")
                breakdownRow(title: "Quality Content", points: qualityPoints, icon: "checkmark.seal")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func breakdownRow(title: String, points: Int, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("+\(points)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(points > 0 ? .green : .secondary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var reputationLevel: String {
        switch userReputation {
        case 0..<50:
            return "Newcomer"
        case 50..<100:
            return "Contributor"
        case 100..<250:
            return "Trusted"
        case 250..<500:
            return "Veteran"
        case 500..<1000:
            return "Expert"
        default:
            return "Legend"
        }
    }
    
    private var nextLevelName: String {
        switch userReputation {
        case 0..<50:
            return "Contributor"
        case 50..<100:
            return "Trusted"
        case 100..<250:
            return "Veteran"
        case 250..<500:
            return "Expert"
        case 500..<1000:
            return "Legend"
        default:
            return "Max Level"
        }
    }
    
    private var pointsToNextLevel: Int {
        switch userReputation {
        case 0..<50:
            return 50 - userReputation
        case 50..<100:
            return 100 - userReputation
        case 100..<250:
            return 250 - userReputation
        case 250..<500:
            return 500 - userReputation
        case 500..<1000:
            return 1000 - userReputation
        default:
            return 0
        }
    }
    
    private var reputationColor: Color {
        switch userReputation {
        case 0..<50:
            return .gray
        case 50..<100:
            return .blue
        case 100..<250:
            return .green
        case 250..<500:
            return .orange
        case 500..<1000:
            return .purple
        default:
            return .gold
        }
    }
    
    private var reputationIcon: String {
        switch userReputation {
        case 0..<50:
            return "person"
        case 50..<100:
            return "person.badge.plus"
        case 100..<250:
            return "checkmark.shield"
        case 250..<500:
            return "star.circle"
        case 500..<1000:
            return "crown"
        default:
            return "trophy"
        }
    }
    
    // Calculate points by category
    private var postPoints: Int {
        reputationHistory.filter { 
            $0.action == .postUpvote || $0.action == .qualityPost 
        }.reduce(0) { $0 + $1.points }
    }
    
    private var reviewPoints: Int {
        reputationHistory.filter { 
            $0.action == .reviewUpvote || $0.action == .helpfulReview 
        }.reduce(0) { $0 + $1.points }
    }
    
    private var commentPoints: Int {
        reputationHistory.filter { 
            $0.action == .commentUpvote 
        }.reduce(0) { $0 + $1.points }
    }
    
    private var qualityPoints: Int {
        reputationHistory.filter { 
            $0.action == .helpfulReview || $0.action == .qualityPost 
        }.reduce(0) { $0 + $1.points }
    }
    
    // MARK: - Data Loading
    
    private func loadProfileData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let reputation = reputationService.getUserReputation(userId: userId)
            async let userAchievements = reputationService.getUserAchievements(userId: userId)
            async let history = reputationService.getReputationHistory(userId: userId, limit: 20)
            
            userReputation = try await reputation
            achievements = try await userAchievements
            reputationHistory = try await history
            
        } catch {
            errorMessage = "Failed to load profile data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Achievement Badge View

struct AchievementBadgeView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [achievementColor.opacity(0.3), achievementColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievementIcon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Text(achievement.type.title)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var achievementColor: Color {
        switch achievement.type {
        case .firstPost, .firstReview:
            return .blue
        case .helpfulContributor:
            return .green
        case .trustedMember:
            return .orange
        case .communityLeader:
            return .purple
        case .moderator:
            return .red
        case .veteran:
            return .brown
        case .topContributor:
            return .gold
        }
    }
    
    private var achievementIcon: String {
        switch achievement.type {
        case .firstPost:
            return "doc.text"
        case .firstReview:
            return "star"
        case .helpfulContributor:
            return "hand.thumbsup"
        case .trustedMember:
            return "checkmark.shield"
        case .communityLeader:
            return "person.3"
        case .moderator:
            return "shield"
        case .veteran:
            return "clock"
        case .topContributor:
            return "trophy"
        }
    }
}

// MARK: - Reputation Event Row

struct ReputationEventRow: View {
    let event: ReputationEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Icon
            Image(systemName: eventIcon)
                .foregroundColor(eventColor)
                .frame(width: 20)
            
            // Event Description
            VStack(alignment: .leading, spacing: 2) {
                Text(eventDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(event.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Points Change
            Text(pointsText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(event.points > 0 ? .green : .red)
        }
        .padding(.vertical, 4)
    }
    
    private var eventIcon: String {
        switch event.action {
        case .postUpvote, .reviewUpvote, .commentUpvote:
            return "arrow.up.circle"
        case .postDownvote, .reviewDownvote, .commentDownvote:
            return "arrow.down.circle"
        case .helpfulReview:
            return "star.circle"
        case .qualityPost:
            return "checkmark.circle"
        case .contentReported:
            return "exclamationmark.triangle"
        case .contentRemoved:
            return "trash.circle"
        }
    }
    
    private var eventColor: Color {
        switch event.action {
        case .postUpvote, .reviewUpvote, .commentUpvote, .helpfulReview, .qualityPost:
            return .green
        case .postDownvote, .reviewDownvote, .commentDownvote:
            return .orange
        case .contentReported, .contentRemoved:
            return .red
        }
    }
    
    private var eventDescription: String {
        switch event.action {
        case .postUpvote:
            return "Post received upvote"
        case .postDownvote:
            return "Post received downvote"
        case .reviewUpvote:
            return "Review received upvote"
        case .reviewDownvote:
            return "Review received downvote"
        case .commentUpvote:
            return "Comment received upvote"
        case .commentDownvote:
            return "Comment received downvote"
        case .helpfulReview:
            return "Review marked as helpful"
        case .qualityPost:
            return "Post marked as quality content"
        case .contentReported:
            return "Content was reported"
        case .contentRemoved:
            return "Content was removed"
        }
    }
    
    private var pointsText: String {
        let sign = event.points > 0 ? "+" : ""
        return "\(sign)\(event.points)"
    }
}

// MARK: - Color Extension

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// MARK: - Preview

struct ReputationProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReputationProfileView(
                userId: UUID(),
                anonymousUsername: "CoolUser123"
            )
        }
    }
}