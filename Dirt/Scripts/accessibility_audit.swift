#!/usr/bin/env swift

import Foundation
import UIKit

/// Accessibility Audit Script for Material Glass Components
/// Performs automated accessibility compliance checks
struct AccessibilityAudit {
    
    // MARK: - Audit Results
    
    struct AuditResult {
        let component: String
        let issues: [AccessibilityIssue]
        let score: Double
        
        var isCompliant: Bool {
            return issues.isEmpty
        }
    }
    
    struct AccessibilityIssue {
        let severity: Severity
        let description: String
        let recommendation: String
        
        enum Severity: String, CaseIterable {
            case critical = "CRITICAL"
            case warning = "WARNING"
            case info = "INFO"
        }
    }
    
    // MARK: - Audit Configuration
    
    struct AuditConfig {
        let minimumContrastRatio: Double = 4.5
        let minimumTouchTargetSize: CGSize = CGSize(width: 44, height: 44)
        let maximumTextLength: Int = 120 // For accessibility labels
        let checkDynamicType: Bool = true
        let checkVoiceOverSupport: Bool = true
        let checkReducedMotion: Bool = true
    }
    
    // MARK: - Component Definitions
    
    struct ComponentDefinition {
        let name: String
        let filePath: String
        let expectedAccessibilityFeatures: [AccessibilityFeature]
    }
    
    enum AccessibilityFeature: String, CaseIterable {
        case accessibilityLabel = "accessibilityLabel"
        case accessibilityHint = "accessibilityHint"
        case accessibilityTraits = "accessibilityTraits"
        case minimumTouchTarget = "minimumTouchTarget"
        case dynamicTypeSupport = "dynamicTypeSupport"
        case focusSupport = "focusSupport"
        case highContrastSupport = "highContrastSupport"
        case reducedMotionSupport = "reducedMotionSupport"
        case voiceOverAnnouncements = "voiceOverAnnouncements"
        case keyboardNavigation = "keyboardNavigation"
    }
    
    // MARK: - Audit Implementation
    
    static func performAudit() -> [AuditResult] {
        let config = AuditConfig()
        let components = getComponentDefinitions()
        
        var results: [AuditResult] = []
        
        for component in components {
            let issues = auditComponent(component, config: config)
            let score = calculateAccessibilityScore(issues: issues)
            
            results.append(AuditResult(
                component: component.name,
                issues: issues,
                score: score
            ))
        }
        
        return results
    }
    
    private static func getComponentDefinitions() -> [ComponentDefinition] {
        return [
            ComponentDefinition(
                name: "GlassButton",
                filePath: "Dirt/Dirt/Core/Design/GlassComponents.swift",
                expectedAccessibilityFeatures: [
                    .accessibilityLabel,
                    .accessibilityHint,
                    .accessibilityTraits,
                    .minimumTouchTarget,
                    .dynamicTypeSupport,
                    .focusSupport,
                    .highContrastSupport,
                    .reducedMotionSupport
                ]
            ),
            ComponentDefinition(
                name: "GlassCard",
                filePath: "Dirt/Dirt/Core/Design/GlassComponents.swift",
                expectedAccessibilityFeatures: [
                    .accessibilityLabel,
                    .accessibilityTraits,
                    .dynamicTypeSupport,
                    .focusSupport,
                    .highContrastSupport
                ]
            ),
            ComponentDefinition(
                name: "GlassSearchBar",
                filePath: "Dirt/Dirt/Core/Design/GlassComponents.swift",
                expectedAccessibilityFeatures: [
                    .accessibilityLabel,
                    .accessibilityHint,
                    .accessibilityTraits,
                    .minimumTouchTarget,
                    .dynamicTypeSupport,
                    .focusSupport,
                    .keyboardNavigation
                ]
            ),
            ComponentDefinition(
                name: "GlassToast",
                filePath: "Dirt/Dirt/Core/Design/GlassComponents.swift",
                expectedAccessibilityFeatures: [
                    .accessibilityLabel,
                    .accessibilityTraits,
                    .voiceOverAnnouncements,
                    .dynamicTypeSupport,
                    .reducedMotionSupport
                ]
            ),
            ComponentDefinition(
                name: "GlassNavigationBar",
                filePath: "Dirt/Dirt/Core/Design/GlassComponents.swift",
                expectedAccessibilityFeatures: [
                    .accessibilityLabel,
                    .accessibilityTraits,
                    .minimumTouchTarget,
                    .dynamicTypeSupport,
                    .highContrastSupport
                ]
            ),
            ComponentDefinition(
                name: "GlassTabBar",
                filePath: "Dirt/Dirt/Core/Design/GlassComponents.swift",
                expectedAccessibilityFeatures: [
                    .accessibilityLabel,
                    .accessibilityHint,
                    .accessibilityTraits,
                    .minimumTouchTarget,
                    .dynamicTypeSupport,
                    .voiceOverAnnouncements,
                    .keyboardNavigation
                ]
            ),
            ComponentDefinition(
                name: "GlassModal",
                filePath: "Dirt/Dirt/Core/Design/GlassComponents.swift",
                expectedAccessibilityFeatures: [
                    .accessibilityLabel,
                    .accessibilityTraits,
                    .voiceOverAnnouncements,
                    .dynamicTypeSupport,
                    .focusSupport,
                    .keyboardNavigation
                ]
            )
        ]
    }
    
    private static func auditComponent(_ component: ComponentDefinition, config: AuditConfig) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // Read component file
        guard let fileContent = readFile(at: component.filePath) else {
            issues.append(AccessibilityIssue(
                severity: .critical,
                description: "Could not read component file: \(component.filePath)",
                recommendation: "Ensure the file exists and is readable"
            ))
            return issues
        }
        
        // Check for required accessibility features
        for feature in component.expectedAccessibilityFeatures {
            if !checkFeatureImplementation(feature, in: fileContent, component: component.name) {
                let severity: AccessibilityIssue.Severity = feature.isCritical ? .critical : .warning
                issues.append(AccessibilityIssue(
                    severity: severity,
                    description: "Missing \(feature.rawValue) implementation in \(component.name)",
                    recommendation: getRecommendation(for: feature)
                ))
            }
        }
        
        // Check for accessibility anti-patterns
        issues.append(contentsOf: checkAntiPatterns(in: fileContent, component: component.name))
        
        // Check for proper contrast considerations
        issues.append(contentsOf: checkContrastConsiderations(in: fileContent, component: component.name))
        
        return issues
    }
    
    private static func checkFeatureImplementation(_ feature: AccessibilityFeature, in content: String, component: String) -> Bool {
        switch feature {
        case .accessibilityLabel:
            return content.contains("accessibilityLabel") || content.contains("glassAccessible")
        case .accessibilityHint:
            return content.contains("accessibilityHint")
        case .accessibilityTraits:
            return content.contains("accessibilityTraits") || content.contains("accessibilityAddTraits")
        case .minimumTouchTarget:
            return content.contains("accessibleTouchTarget") || content.contains("minHeight") || content.contains("minWidth")
        case .dynamicTypeSupport:
            return content.contains("DynamicType.scaledFont") || content.contains("DynamicType.scaledSpacing")
        case .focusSupport:
            return content.contains("@FocusState") || content.contains("focused") || content.contains("glassFocusRing")
        case .highContrastSupport:
            return content.contains("glassHighContrast") || content.contains("AccessibleColors")
        case .reducedMotionSupport:
            return content.contains("ReducedMotion") || content.contains("isReduceMotionEnabled")
        case .voiceOverAnnouncements:
            return content.contains("UIAccessibility.post") || content.contains("announcement")
        case .keyboardNavigation:
            return content.contains("@FocusState") || content.contains("onSubmit") || content.contains("focused")
        }
    }
    
    private static func checkAntiPatterns(in content: String, component: String) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // Check for hardcoded font sizes without Dynamic Type support
        if content.contains(".font(.system(size:") && !content.contains("DynamicType.scaledFont") {
            issues.append(AccessibilityIssue(
                severity: .warning,
                description: "Hardcoded font sizes detected in \(component)",
                recommendation: "Use AccessibilitySystem.DynamicType.scaledFont() for Dynamic Type support"
            ))
        }
        
        // Check for hardcoded spacing without Dynamic Type support
        if content.contains(".padding(") && !content.contains("DynamicType.scaledSpacing") {
            issues.append(AccessibilityIssue(
                severity: .info,
                description: "Hardcoded spacing detected in \(component)",
                recommendation: "Consider using AccessibilitySystem.DynamicType.scaledSpacing() for better accessibility"
            ))
        }
        
        // Check for animations without reduced motion consideration
        if content.contains("withAnimation") && !content.contains("ReducedMotion") {
            issues.append(AccessibilityIssue(
                severity: .warning,
                description: "Animations without reduced motion support in \(component)",
                recommendation: "Use AccessibilitySystem.ReducedMotion.animation() to respect user preferences"
            ))
        }
        
        // Check for missing accessibility labels on interactive elements
        if content.contains("Button(") && !content.contains("accessibilityLabel") {
            issues.append(AccessibilityIssue(
                severity: .critical,
                description: "Interactive elements without accessibility labels in \(component)",
                recommendation: "Add accessibilityLabel to all interactive elements"
            ))
        }
        
        return issues
    }
    
    private static func checkContrastConsiderations(in content: String, component: String) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // Check if component uses accessible colors
        if !content.contains("AccessibleColors") && (content.contains("Color(") || content.contains("UIColors")) {
            issues.append(AccessibilityIssue(
                severity: .warning,
                description: "Component \(component) may not use accessible colors",
                recommendation: "Use AccessibilitySystem.AccessibleColors for better contrast compliance"
            ))
        }
        
        // Check for proper Material background usage
        if content.contains("Material") && !content.contains("AccessibilitySystem") {
            issues.append(AccessibilityIssue(
                severity: .info,
                description: "Material backgrounds in \(component) should consider accessibility",
                recommendation: "Ensure text on Material backgrounds meets contrast requirements"
            ))
        }
        
        return issues
    }
    
    private static func calculateAccessibilityScore(issues: [AccessibilityIssue]) -> Double {
        let totalPossiblePoints = 100.0
        var deductions = 0.0
        
        for issue in issues {
            switch issue.severity {
            case .critical:
                deductions += 25.0
            case .warning:
                deductions += 10.0
            case .info:
                deductions += 2.0
            }
        }
        
        return max(0.0, totalPossiblePoints - deductions)
    }
    
    private static func getRecommendation(for feature: AccessibilityFeature) -> String {
        switch feature {
        case .accessibilityLabel:
            return "Add .accessibilityLabel() or use .glassAccessible() modifier"
        case .accessibilityHint:
            return "Add .accessibilityHint() to provide usage instructions"
        case .accessibilityTraits:
            return "Add appropriate .accessibilityAddTraits() for component type"
        case .minimumTouchTarget:
            return "Use .accessibleTouchTarget() modifier to ensure 44x44pt minimum"
        case .dynamicTypeSupport:
            return "Use AccessibilitySystem.DynamicType.scaledFont() and scaledSpacing()"
        case .focusSupport:
            return "Add @FocusState and .glassFocusRing() for keyboard navigation"
        case .highContrastSupport:
            return "Use .glassHighContrast() modifier and AccessibleColors"
        case .reducedMotionSupport:
            return "Use AccessibilitySystem.ReducedMotion.animation() for animations"
        case .voiceOverAnnouncements:
            return "Add UIAccessibility.post() announcements for state changes"
        case .keyboardNavigation:
            return "Implement proper focus management and keyboard shortcuts"
        }
    }
    
    private static func readFile(at path: String) -> String? {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    // MARK: - Report Generation
    
    static func generateReport(results: [AuditResult]) -> String {
        var report = """
        # Material Glass Accessibility Audit Report
        
        Generated: \(Date())
        
        ## Summary
        
        """
        
        let totalComponents = results.count
        let compliantComponents = results.filter { $0.isCompliant }.count
        let averageScore = results.map { $0.score }.reduce(0, +) / Double(totalComponents)
        
        report += """
        - Total Components Audited: \(totalComponents)
        - Compliant Components: \(compliantComponents)
        - Compliance Rate: \(String(format: "%.1f", Double(compliantComponents) / Double(totalComponents) * 100))%
        - Average Accessibility Score: \(String(format: "%.1f", averageScore))/100
        
        ## Component Results
        
        """
        
        for result in results.sorted(by: { $0.score > $1.score }) {
            report += """
            ### \(result.component)
            
            **Score:** \(String(format: "%.1f", result.score))/100
            **Status:** \(result.isCompliant ? "✅ Compliant" : "❌ Issues Found")
            
            """
            
            if !result.issues.isEmpty {
                report += "**Issues:**\n\n"
                
                for issue in result.issues {
                    let emoji = issue.severity == .critical ? "🔴" : issue.severity == .warning ? "🟡" : "🔵"
                    report += """
                    \(emoji) **\(issue.severity.rawValue):** \(issue.description)
                    
                    *Recommendation:* \(issue.recommendation)
                    
                    """
                }
            }
            
            report += "\n"
        }
        
        // Add recommendations section
        report += """
        ## Overall Recommendations
        
        ### Critical Issues
        
        """
        
        let criticalIssues = results.flatMap { $0.issues }.filter { $0.severity == .critical }
        if criticalIssues.isEmpty {
            report += "✅ No critical accessibility issues found.\n\n"
        } else {
            for issue in Set(criticalIssues.map { $0.description }) {
                report += "- \(issue)\n"
            }
            report += "\n"
        }
        
        report += """
        ### Best Practices
        
        1. **Always provide accessibility labels** for interactive elements
        2. **Use Dynamic Type scaling** for all text and spacing
        3. **Implement focus management** for keyboard navigation
        4. **Respect reduced motion preferences** in animations
        5. **Ensure sufficient contrast ratios** on glass backgrounds
        6. **Test with VoiceOver** regularly during development
        7. **Validate touch target sizes** meet 44x44pt minimum
        
        ### Testing Checklist
        
        - [ ] Test with VoiceOver enabled
        - [ ] Test with largest Dynamic Type size
        - [ ] Test with reduced motion enabled
        - [ ] Test with high contrast enabled
        - [ ] Test keyboard navigation
        - [ ] Validate color contrast ratios
        - [ ] Test on different screen sizes
        
        """
        
        return report
    }
}

// MARK: - Feature Extensions

extension AccessibilityAudit.AccessibilityFeature {
    var isCritical: Bool {
        switch self {
        case .accessibilityLabel, .accessibilityTraits, .minimumTouchTarget:
            return true
        default:
            return false
        }
    }
}

// MARK: - Main Execution

let auditResults = AccessibilityAudit.performAudit()
let report = AccessibilityAudit.generateReport(results: auditResults)

print(report)

// Write report to file
let reportPath = "accessibility_audit_report.md"
do {
    try report.write(toFile: reportPath, atomically: true, encoding: .utf8)
    print("\n📄 Report saved to: \(reportPath)")
} catch {
    print("\n❌ Failed to save report: \(error)")
}

// Exit with appropriate code
let hasIssues = auditResults.contains { !$0.isCompliant }
exit(hasIssues ? 1 : 0)