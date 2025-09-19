#!/bin/bash

# Final Integration and Validation Testing Script
# This script performs comprehensive testing for the Dirt architecture refactor

set -e

echo "🧪 Starting Final Integration and Validation Testing"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to log test results
log_test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        if [ -n "$details" ]; then
            echo -e "   ${YELLOW}Details:${NC} $details"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to check if file exists and has content
check_file_exists() {
    local file_path="$1"
    local description="$2"
    
    if [ -f "$file_path" ] && [ -s "$file_path" ]; then
        log_test_result "$description" "PASS"
        return 0
    else
        log_test_result "$description" "FAIL" "File missing or empty: $file_path"
        return 1
    fi
}

# Function to check directory structure
check_directory_structure() {
    echo -e "\n${BLUE}📁 Validating Directory Structure${NC}"
    
    # Core architecture directories
    check_file_exists "Dirt/Core/Design/MaterialDesignSystem.swift" "Core Design System exists"
    check_file_exists "Dirt/Core/Design/GlassComponents.swift" "Glass Components exist"
    check_file_exists "Dirt/Core/Design/MotionSystem.swift" "Motion System exists"
    check_file_exists "Dirt/Core/Navigation/NavigationCoordinator.swift" "Navigation Coordinator exists"
    check_file_exists "Dirt/Core/Services/ServiceContainer.swift" "Service Container exists"
    
    # Feature directories
    local features=("Feed" "Search" "CreatePost" "Profile" "Notifications" "Settings")
    for feature in "${features[@]}"; do
        if [ -d "Dirt/Features/$feature" ]; then
            log_test_result "Feature directory: $feature" "PASS"
        else
            log_test_result "Feature directory: $feature" "FAIL" "Directory missing"
        fi
    done
    
    # Shared components
    check_file_exists "Dirt/Shared/Utilities/Validation.swift" "Shared Validation utilities exist"
    check_file_exists "Dirt/Shared/Utilities/ReportService.swift" "Report Service exists"
}

# Function to validate Material Glass implementation
check_material_glass_implementation() {
    echo -e "\n${BLUE}🎨 Validating Material Glass Implementation${NC}"
    
    # Check for Material Glass components
    if grep -q "MaterialDesignSystem\|\.ultraThinMaterial\|\.thinMaterial\|\.regularMaterial\|\.thickMaterial" "Dirt/Core/Design/GlassComponents.swift" 2>/dev/null; then
        log_test_result "Material Glass effects implemented" "PASS"
    else
        log_test_result "Material Glass effects implemented" "FAIL" "No Material effects found in GlassComponents"
    fi
    
    # Check for proper Material usage in views
    local material_usage_count=0
    for view_file in $(find Dirt/Features -name "*.swift" -type f); do
        if grep -q "GlassCard\|GlassButton\|MaterialDesignSystem\|\.ultraThinMaterial\|\.thinMaterial\|\.regularMaterial\|\.thickMaterial" "$view_file" 2>/dev/null; then
            material_usage_count=$((material_usage_count + 1))
        fi
    done
    
    if [ $material_usage_count -gt 0 ]; then
        log_test_result "Material Glass used in feature views" "PASS" "Found in $material_usage_count files"
    else
        log_test_result "Material Glass used in feature views" "FAIL" "No Material usage found in feature views"
    fi
}

# Function to validate service consolidation
check_service_consolidation() {
    echo -e "\n${BLUE}🔧 Validating Service Consolidation${NC}"
    
    # Check that duplicate services have been consolidated
    local enhanced_services=$(find Dirt -name "*Enhanced*Service.swift" -type f | wc -l)
    if [ $enhanced_services -eq 0 ]; then
        log_test_result "Enhanced services consolidated" "PASS"
    else
        log_test_result "Enhanced services consolidated" "FAIL" "Found $enhanced_services Enhanced services still present"
    fi
    
    # Check for service container usage
    if grep -r "ServiceContainer" Dirt/Features/ >/dev/null 2>&1; then
        log_test_result "Service Container pattern implemented" "PASS"
    else
        log_test_result "Service Container pattern implemented" "FAIL" "No ServiceContainer usage found in features"
    fi
}

# Function to validate PLAN.md milestone features
check_milestone_features() {
    echo -e "\n${BLUE}🎯 Validating PLAN.md Milestone Features${NC}"
    
    # M1: Parity analysis - Check for controlled tags
    if grep -q "ControlledTag\|enum.*Tag" Dirt/Models/ControlledTags.swift 2>/dev/null; then
        log_test_result "M1: Controlled tags implemented" "PASS"
    else
        log_test_result "M1: Controlled tags implemented" "FAIL"
    fi
    
    # M2: Create Post v2 - Check for character counter and validation
    if grep -q "500" Dirt/Features/CreatePost/Views/CreatePostView.swift 2>/dev/null; then
        log_test_result "M2: Create Post character limit" "PASS"
    else
        log_test_result "M2: Create Post character limit" "FAIL"
    fi
    
    # M3: Search functionality
    if [ -f "Dirt/Features/Search/Views/SearchView.swift" ]; then
        log_test_result "M3: Search functionality exists" "PASS"
    else
        log_test_result "M3: Search functionality exists" "FAIL"
    fi
    
    # M4: Report flow
    if [ -f "Dirt/Shared/Utilities/ReportService.swift" ]; then
        log_test_result "M4: Report flow implemented" "PASS"
    else
        log_test_result "M4: Report flow implemented" "FAIL"
    fi
    
    # M5: Visual polish - Check for Material Glass usage
    local glass_usage=$(grep -r "GlassCard\|GlassButton\|MaterialDesignSystem" Dirt/Features/ | wc -l)
    if [ $glass_usage -gt 0 ]; then
        log_test_result "M5: Visual polish (Material Glass)" "PASS" "Found $glass_usage Material usages"
    else
        log_test_result "M5: Visual polish (Material Glass)" "FAIL"
    fi
}

# Function to check accessibility compliance
check_accessibility_compliance() {
    echo -e "\n${BLUE}♿ Validating Accessibility Compliance${NC}"
    
    # Check for accessibility system
    check_file_exists "Dirt/Core/Design/AccessibilitySystem.swift" "Accessibility System exists"
    
    # Check for accessibility documentation
    check_file_exists "Dirt/Core/Design/ACCESSIBILITY.md" "Accessibility documentation exists"
    
    # Check for accessibility in Material Glass components
    if grep -q "accessibilityLabel\|accessibilityHint\|accessibilityValue" Dirt/Core/Design/GlassComponents.swift 2>/dev/null; then
        log_test_result "Material Glass accessibility labels" "PASS"
    else
        log_test_result "Material Glass accessibility labels" "FAIL"
    fi
}

# Function to validate performance optimizations
check_performance_optimizations() {
    echo -e "\n${BLUE}⚡ Validating Performance Optimizations${NC}"
    
    # Check for lazy loading in service container
    if grep -q "lazy var" Dirt/Core/Services/ServiceContainer.swift 2>/dev/null; then
        log_test_result "Lazy loading in ServiceContainer" "PASS"
    else
        log_test_result "Lazy loading in ServiceContainer" "FAIL"
    fi
    
    # Check for performance monitoring
    if [ -f "Scripts/measure_build_performance.sh" ]; then
        log_test_result "Build performance monitoring script exists" "PASS"
    else
        log_test_result "Build performance monitoring script exists" "FAIL"
    fi
    
    # Check for animation optimization
    if grep -q "\.animation\|Animation\." Dirt/Core/Design/MotionSystem.swift 2>/dev/null; then
        log_test_result "Animation system implemented" "PASS"
    else
        log_test_result "Animation system implemented" "FAIL"
    fi
}

# Function to validate documentation
check_documentation() {
    echo -e "\n${BLUE}📚 Validating Documentation${NC}"
    
    # Check for README files in major directories
    local readme_dirs=("Dirt/Core" "Dirt/Core/Design" "Dirt/Core/Services" "Dirt/Core/Navigation" "Dirt/Features" "Dirt/Shared")
    for dir in "${readme_dirs[@]}"; do
        if [ -f "$dir/README.md" ]; then
            log_test_result "README exists: $dir" "PASS"
        else
            log_test_result "README exists: $dir" "FAIL"
        fi
    done
    
    # Check for architectural decision records
    if [ -d "../docs/architecture" ] && [ "$(ls -A ../docs/architecture/ADR-*.md 2>/dev/null | wc -l)" -gt 0 ]; then
        log_test_result "Architectural Decision Records exist" "PASS"
    else
        log_test_result "Architectural Decision Records exist" "FAIL"
    fi
    
    # Check for coding standards
    check_file_exists "../docs/CODING_STANDARDS.md" "Coding standards documentation exists"
}

# Function to run syntax validation
check_syntax_validation() {
    echo -e "\n${BLUE}🔍 Validating Swift Syntax${NC}"
    
    # Check for basic Swift syntax errors by attempting to compile key files
    local syntax_errors=0
    
    # Check Core files
    for swift_file in $(find Dirt/Core -name "*.swift" -type f); do
        if ! swift -frontend -parse "$swift_file" >/dev/null 2>&1; then
            log_test_result "Syntax check: $(basename $swift_file)" "FAIL" "Syntax errors found"
            syntax_errors=$((syntax_errors + 1))
        fi
    done
    
    if [ $syntax_errors -eq 0 ]; then
        log_test_result "Swift syntax validation" "PASS" "No syntax errors found in Core files"
    else
        log_test_result "Swift syntax validation" "FAIL" "$syntax_errors files with syntax errors"
    fi
}

# Function to validate test coverage
check_test_coverage() {
    echo -e "\n${BLUE}🧪 Validating Test Coverage${NC}"
    
    # Count test files
    local unit_tests=$(find DirtTests -name "*Tests.swift" -type f | wc -l)
    local ui_tests=$(find DirtUITests -name "*Tests.swift" -type f | wc -l)
    
    if [ $unit_tests -gt 20 ]; then
        log_test_result "Unit test coverage" "PASS" "$unit_tests test files found"
    else
        log_test_result "Unit test coverage" "FAIL" "Only $unit_tests test files found"
    fi
    
    if [ $ui_tests -gt 0 ]; then
        log_test_result "UI test coverage" "PASS" "$ui_tests UI test files found"
    else
        log_test_result "UI test coverage" "FAIL" "No UI test files found"
    fi
    
    # Check for Material Glass specific tests
    local material_tests=$(find DirtTests -name "*MaterialGlass*Tests.swift" -type f | wc -l)
    if [ $material_tests -gt 5 ]; then
        log_test_result "Material Glass test coverage" "PASS" "$material_tests Material Glass test files"
    else
        log_test_result "Material Glass test coverage" "FAIL" "Only $material_tests Material Glass test files"
    fi
}

# Main execution
echo -e "${BLUE}Starting comprehensive validation...${NC}\n"

# Run all validation checks
check_directory_structure
check_material_glass_implementation
check_service_consolidation
check_milestone_features
check_accessibility_compliance
check_performance_optimizations
check_documentation
check_syntax_validation
check_test_coverage

# Final summary
echo -e "\n${BLUE}=================================================="
echo -e "📊 FINAL VALIDATION SUMMARY"
echo -e "==================================================${NC}"
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL VALIDATION TESTS PASSED!${NC}"
    echo -e "${GREEN}The Dirt architecture refactor is complete and ready for production.${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  VALIDATION ISSUES FOUND${NC}"
    echo -e "${YELLOW}Please address the failed tests before considering the refactor complete.${NC}"
    exit 1
fi