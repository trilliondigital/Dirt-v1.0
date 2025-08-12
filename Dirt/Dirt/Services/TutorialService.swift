import Foundation
import SwiftUI

// MARK: - Tutorial Types

struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let targetView: String?
    let position: TooltipPosition
    let action: TutorialAction?
    let isSkippable: Bool
    
    enum TooltipPosition {
        case top
        case bottom
        case leading
        case trailing
        case center
    }
    
    enum TutorialAction {
        case tap
        case swipe(direction: SwipeDirection)
        case longPress
        case none
        
        enum SwipeDirection {
            case up, down, left, right
        }
    }
}

struct Tutorial: Identifiable {
    let id: String
    let name: String
    let description: String
    let steps: [TutorialStep]
    let isRequired: Bool
    let version: String
}

// MARK: - Tutorial Service

@MainActor
class TutorialService: ObservableObject {
    static let shared = TutorialService()
    
    @Published var currentTutorial: Tutorial?
    @Published var currentStepIndex = 0
    @Published var isShowingTutorial = false
    @Published var completedTutorials: Set<String> = []
    @Published var availableTutorials: [Tutorial] = []
    
    private let completedTutorialsKey = "completedTutorials"
    private let tutorialVersionKey = "tutorialVersion"
    
    private init() {
        loadCompletedTutorials()
        setupAvailableTutorials()
    }
    
    private func setupAvailableTutorials() {
        availableTutorials = [
            createOnboardingTutorial(),
            createFeedTutorial(),
            createPostCreationTutorial(),
            createSearchTutorial(),
            createProfileTutorial()
        ]
    }
    
    func startTutorial(_ tutorial: Tutorial) {
        currentTutorial = tutorial
        currentStepIndex = 0
        isShowingTutorial = true
    }
    
    func nextStep() {
        guard let tutorial = currentTutorial else { return }
        
        if currentStepIndex < tutorial.steps.count - 1 {
            currentStepIndex += 1
        } else {
            completeTutorial()
        }
    }
    
    func previousStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
        }
    }
    
    func skipTutorial() {
        guard let tutorial = currentTutorial,
              tutorial.steps[currentStepIndex].isSkippable else { return }
        
        completeTutorial()
    }
    
    func completeTutorial() {
        guard let tutorial = currentTutorial else { return }
        
        completedTutorials.insert(tutorial.id)
        saveCompletedTutorials()
        
        currentTutorial = nil
        currentStepIndex = 0
        isShowingTutorial = false
    }
    
    func shouldShowTutorial(_ tutorialId: String) -> Bool {
        return !completedTutorials.contains(tutorialId)
    }
    
    func resetTutorial(_ tutorialId: String) {
        completedTutorials.remove(tutorialId)
        saveCompletedTutorials()
    }
    
    func resetAllTutorials() {
        completedTutorials.removeAll()
        saveCompletedTutorials()
    }
    
    private func loadCompletedTutorials() {
        if let data = UserDefaults.standard.data(forKey: completedTutorialsKey),
           let tutorials = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedTutorials = tutorials
        }
    }
    
    private func saveCompletedTutorials() {
        if let data = try? JSONEncoder().encode(completedTutorials) {
            UserDefaults.standard.set(data, forKey: completedTutorialsKey)
        }
    }
    
    // MARK: - Tutorial Definitions
    
    private func createOnboardingTutorial() -> Tutorial {
        Tutorial(
            id: "onboarding",
            name: "Welcome to Dirt",
            description: "Learn the basics of using Dirt",
            steps: [
                TutorialStep(
                    title: "Welcome!",
                    description: "Welcome to Dirt! Let's take a quick tour to get you started.",
                    targetView: nil,
                    position: .center,
                    action: .none,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Home Feed",
                    description: "This is your home feed where you'll see posts from people you follow.",
                    targetView: "homeFeed",
                    position: .bottom,
                    action: .none,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Create Post",
                    description: "Tap here to create a new post and share your thoughts.",
                    targetView: "createPostButton",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Search",
                    description: "Use the search tab to find posts, users, and topics.",
                    targetView: "searchTab",
                    position: .top,
                    action: .tap,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Profile",
                    description: "Access your profile and settings from here.",
                    targetView: "profileTab",
                    position: .top,
                    action: .tap,
                    isSkippable: true
                )
            ],
            isRequired: true,
            version: "1.0"
        )
    }
    
    private func createFeedTutorial() -> Tutorial {
        Tutorial(
            id: "feed",
            name: "Using the Feed",
            description: "Learn how to interact with posts in your feed",
            steps: [
                TutorialStep(
                    title: "Like Posts",
                    description: "Double-tap a post to like it, or use the heart button.",
                    targetView: "postCard",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Pull to Refresh",
                    description: "Pull down on the feed to refresh and see new posts.",
                    targetView: "feedScrollView",
                    position: .top,
                    action: .swipe(direction: .down),
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Swipe Actions",
                    description: "Swipe left on a post to access quick actions like save and share.",
                    targetView: "postCard",
                    position: .trailing,
                    action: .swipe(direction: .left),
                    isSkippable: true
                )
            ],
            isRequired: false,
            version: "1.0"
        )
    }
    
    private func createPostCreationTutorial() -> Tutorial {
        Tutorial(
            id: "postCreation",
            name: "Creating Posts",
            description: "Learn how to create and share posts",
            steps: [
                TutorialStep(
                    title: "Add Media",
                    description: "Tap here to add photos or videos to your post.",
                    targetView: "addMediaButton",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Add Topics",
                    description: "Tag your post with relevant topics to help others discover it.",
                    targetView: "addTopicsButton",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Post Options",
                    description: "Access additional options like privacy settings and scheduling.",
                    targetView: "postOptionsButton",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                )
            ],
            isRequired: false,
            version: "1.0"
        )
    }
    
    private func createSearchTutorial() -> Tutorial {
        Tutorial(
            id: "search",
            name: "Search & Discovery",
            description: "Learn how to find content and people",
            steps: [
                TutorialStep(
                    title: "Search Bar",
                    description: "Type here to search for posts, users, topics, and hashtags.",
                    targetView: "searchBar",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Search Filters",
                    description: "Use filters to narrow down your search results.",
                    targetView: "searchFiltersButton",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Save Searches",
                    description: "Save frequently used searches for quick access later.",
                    targetView: "saveSearchButton",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                )
            ],
            isRequired: false,
            version: "1.0"
        )
    }
    
    private func createProfileTutorial() -> Tutorial {
        Tutorial(
            id: "profile",
            name: "Your Profile",
            description: "Learn about profile features and settings",
            steps: [
                TutorialStep(
                    title: "Edit Profile",
                    description: "Tap here to edit your profile information and photo.",
                    targetView: "editProfileButton",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Settings",
                    description: "Access app settings, privacy controls, and preferences.",
                    targetView: "settingsButton",
                    position: .bottom,
                    action: .tap,
                    isSkippable: true
                ),
                TutorialStep(
                    title: "Your Posts",
                    description: "View and manage all your posts from your profile.",
                    targetView: "userPostsSection",
                    position: .top,
                    action: .none,
                    isSkippable: true
                )
            ],
            isRequired: false,
            version: "1.0"
        )
    }
}

// MARK: - Tutorial UI Components

struct TutorialOverlay: View {
    @StateObject private var tutorialService = TutorialService.shared
    @State private var highlightFrame: CGRect = .zero
    
    var body: some View {
        if tutorialService.isShowingTutorial,
           let tutorial = tutorialService.currentTutorial {
            
            let currentStep = tutorial.steps[tutorialService.currentStepIndex]
            
            ZStack {
                // Dark overlay
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if currentStep.isSkippable {
                            tutorialService.skipTutorial()
                        }
                    }
                
                // Highlight area (if targeting a specific view)
                if let targetView = currentStep.targetView {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: highlightFrame.width + 20, height: highlightFrame.height + 20)
                        .position(x: highlightFrame.midX, y: highlightFrame.midY)
                        .background(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: highlightFrame.width + 20, height: highlightFrame.height + 20)
                        )
                }
                
                // Tutorial tooltip
                TutorialTooltip(
                    step: currentStep,
                    currentIndex: tutorialService.currentStepIndex,
                    totalSteps: tutorial.steps.count,
                    onNext: tutorialService.nextStep,
                    onPrevious: tutorialService.previousStep,
                    onSkip: tutorialService.skipTutorial
                )
            }
            .animation(.easeInOut(duration: 0.3), value: tutorialService.currentStepIndex)
        }
    }
}

struct TutorialTooltip: View {
    let step: TutorialStep
    let currentIndex: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress indicator
            HStack {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= currentIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let action = step.action, action != .none {
                    TutorialActionHint(action: action)
                }
            }
            
            // Navigation buttons
            HStack(spacing: 16) {
                if currentIndex > 0 {
                    Button("Previous") {
                        onPrevious()
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                if step.isSkippable {
                    Button("Skip") {
                        onSkip()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                Button(currentIndex == totalSteps - 1 ? "Done" : "Next") {
                    onNext()
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .cornerRadius(20)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
        )
        .padding(.horizontal, 20)
    }
}

struct TutorialActionHint: View {
    let action: TutorialStep.TutorialAction
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: actionIcon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(actionText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionIcon: String {
        switch action {
        case .tap:
            return "hand.tap"
        case .swipe(let direction):
            switch direction {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .left: return "arrow.left"
            case .right: return "arrow.right"
            }
        case .longPress:
            return "hand.point.up"
        case .none:
            return ""
        }
    }
    
    private var actionText: String {
        switch action {
        case .tap:
            return "Tap to continue"
        case .swipe(let direction):
            return "Swipe \(direction)"
        case .longPress:
            return "Long press"
        case .none:
            return ""
        }
    }
}

// MARK: - Tutorial Management View

struct TutorialManagementView: View {
    @StateObject private var tutorialService = TutorialService.shared
    
    var body: some View {
        List {
            Section("Available Tutorials") {
                ForEach(tutorialService.availableTutorials) { tutorial in
                    TutorialRow(tutorial: tutorial)
                }
            }
            
            Section("Actions") {
                Button("Reset All Tutorials") {
                    tutorialService.resetAllTutorials()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Tutorials")
    }
}

struct TutorialRow: View {
    @StateObject private var tutorialService = TutorialService.shared
    let tutorial: Tutorial
    
    private var isCompleted: Bool {
        tutorialService.completedTutorials.contains(tutorial.id)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tutorial.name)
                    .font(.headline)
                
                Text(tutorial.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(tutorial.steps.count) steps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if tutorial.isRequired {
                    Text("Required")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(isCompleted ? "Restart" : "Start") {
                    if isCompleted {
                        tutorialService.resetTutorial(tutorial.id)
                    }
                    tutorialService.startTutorial(tutorial)
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tutorial View Modifier

struct TutorialTarget: ViewModifier {
    let identifier: String
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: TutorialFramePreferenceKey.self,
                            value: [identifier: geometry.frame(in: .global)]
                        )
                }
            )
    }
}

struct TutorialFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    func tutorialTarget(_ identifier: String) -> some View {
        modifier(TutorialTarget(identifier: identifier))
    }
}
