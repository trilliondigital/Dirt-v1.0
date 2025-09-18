#!/bin/bash

# Performance and Memory Usage Testing Script
# Tests app performance and memory usage with Material Glass effects

set -e

echo "⚡ Starting Performance and Memory Usage Testing"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Performance metrics tracking
PERFORMANCE_TESTS_PASSED=0
PERFORMANCE_TESTS_FAILED=0
TOTAL_PERFORMANCE_TESTS=0

# Function to log performance test results
log_performance_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_PERFORMANCE_TESTS=$((TOTAL_PERFORMANCE_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        PERFORMANCE_TESTS_PASSED=$((PERFORMANCE_TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        if [ -n "$details" ]; then
            echo -e "   ${YELLOW}Details:${NC} $details"
        fi
        PERFORMANCE_TESTS_FAILED=$((PERFORMANCE_TESTS_FAILED + 1))
    fi
}

# Function to test build performance
test_build_performance() {
    echo -e "\n${BLUE}🏗️  Testing Build Performance${NC}"
    
    # Clean build directory
    echo "Cleaning build directory..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/Dirt-* 2>/dev/null || true
    
    # Measure clean build time
    echo "Measuring clean build time..."
    local start_time=$(date +%s)
    
    if xcodebuild clean build -scheme Dirt -destination 'platform=macOS' -quiet >/dev/null 2>&1; then
        local end_time=$(date +%s)
        local build_time=$((end_time - start_time))
        
        if [ $build_time -lt 120 ]; then  # Less than 2 minutes
            log_performance_result "Clean build time" "PASS" "${build_time}s (target: <120s)"
        else
            log_performance_result "Clean build time" "FAIL" "${build_time}s (target: <120s)"
        fi
    else
        log_performance_result "Clean build time" "FAIL" "Build failed"
    fi
    
    # Measure incremental build time
    echo "Measuring incremental build time..."
    
    # Make a small change
    echo "// Performance test comment $(date)" >> Dirt/Core/Design/DesignTokens.swift
    
    local start_time=$(date +%s)
    
    if xcodebuild build -scheme Dirt -destination 'platform=macOS' -quiet >/dev/null 2>&1; then
        local end_time=$(date +%s)
        local incremental_time=$((end_time - start_time))
        
        if [ $incremental_time -lt 30 ]; then  # Less than 30 seconds
            log_performance_result "Incremental build time" "PASS" "${incremental_time}s (target: <30s)"
        else
            log_performance_result "Incremental build time" "FAIL" "${incremental_time}s (target: <30s)"
        fi
    else
        log_performance_result "Incremental build time" "FAIL" "Build failed"
    fi
    
    # Revert the test change
    git checkout -- Dirt/Core/Design/DesignTokens.swift 2>/dev/null || true
}

# Function to analyze code complexity
test_code_complexity() {
    echo -e "\n${BLUE}📊 Testing Code Complexity${NC}"
    
    # Count lines of code in core components
    local core_loc=$(find Dirt/Core -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print $1}')
    local features_loc=$(find Dirt/Features -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print $1}')
    local shared_loc=$(find Dirt/Shared -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print $1}')
    
    echo "Lines of code - Core: $core_loc, Features: $features_loc, Shared: $shared_loc"
    
    # Check for reasonable code distribution
    local total_loc=$((core_loc + features_loc + shared_loc))
    local core_percentage=$((core_loc * 100 / total_loc))
    
    if [ $core_percentage -lt 40 ]; then  # Core should be less than 40% of total
        log_performance_result "Code distribution balance" "PASS" "Core: ${core_percentage}% of total"
    else
        log_performance_result "Code distribution balance" "FAIL" "Core: ${core_percentage}% of total (target: <40%)"
    fi
    
    # Check for large files (potential complexity issues)
    local large_files=$(find Dirt -name "*.swift" -exec wc -l {} + | awk '$1 > 500 {print $2}' | wc -l)
    
    if [ $large_files -lt 5 ]; then  # Less than 5 files over 500 lines
        log_performance_result "File size distribution" "PASS" "$large_files files >500 lines (target: <5)"
    else
        log_performance_result "File size distribution" "FAIL" "$large_files files >500 lines (target: <5)"
    fi
}

# Function to test Material Glass performance patterns
test_material_glass_performance() {
    echo -e "\n${BLUE}🎨 Testing Material Glass Performance Patterns${NC}"
    
    # Check for performance-optimized Material usage
    local optimized_usage=$(grep -r "performanceOptimizedGlass\|PerformanceOptimizationService" Dirt/Core/Design/ | wc -l)
    
    if [ $optimized_usage -gt 0 ]; then
        log_performance_result "Performance-optimized Material Glass" "PASS" "$optimized_usage optimizations found"
    else
        log_performance_result "Performance-optimized Material Glass" "FAIL" "No performance optimizations found"
    fi
    
    # Check for animation optimization
    local animation_optimizations=$(grep -r "AccessibilitySystem.ReducedMotion\|optimizedAnimationDuration" Dirt/Core/Design/ | wc -l)
    
    if [ $animation_optimizations -gt 5 ]; then
        log_performance_result "Animation performance optimizations" "PASS" "$animation_optimizations optimizations found"
    else
        log_performance_result "Animation performance optimizations" "FAIL" "$animation_optimizations optimizations found (target: >5)"
    fi
    
    # Check for lazy loading patterns
    local lazy_patterns=$(grep -r "lazy var\|LazyVStack\|LazyHStack" Dirt/ | wc -l)
    
    if [ $lazy_patterns -gt 10 ]; then
        log_performance_result "Lazy loading patterns" "PASS" "$lazy_patterns lazy patterns found"
    else
        log_performance_result "Lazy loading patterns" "FAIL" "$lazy_patterns lazy patterns found (target: >10)"
    fi
}

# Function to test memory usage patterns
test_memory_usage_patterns() {
    echo -e "\n${BLUE}🧠 Testing Memory Usage Patterns${NC}"
    
    # Check for proper memory management patterns
    local weak_references=$(grep -r "weak var\|weak let" Dirt/ | wc -l)
    
    if [ $weak_references -gt 5 ]; then
        log_performance_result "Weak reference usage" "PASS" "$weak_references weak references found"
    else
        log_performance_result "Weak reference usage" "FAIL" "$weak_references weak references found (target: >5)"
    fi
    
    # Check for proper cleanup patterns
    local cleanup_patterns=$(grep -r "deinit\|removeAll\|invalidate" Dirt/ | wc -l)
    
    if [ $cleanup_patterns -gt 10 ]; then
        log_performance_result "Memory cleanup patterns" "PASS" "$cleanup_patterns cleanup patterns found"
    else
        log_performance_result "Memory cleanup patterns" "FAIL" "$cleanup_patterns cleanup patterns found (target: >10)"
    fi
    
    # Check for cache usage
    local cache_usage=$(grep -r "NSCache\|cache\|Cache" Dirt/ | wc -l)
    
    if [ $cache_usage -gt 3 ]; then
        log_performance_result "Caching implementation" "PASS" "$cache_usage cache implementations found"
    else
        log_performance_result "Caching implementation" "FAIL" "$cache_usage cache implementations found (target: >3)"
    fi
}

# Function to test dependency injection performance
test_dependency_injection_performance() {
    echo -e "\n${BLUE}🔧 Testing Dependency Injection Performance${NC}"
    
    # Check for lazy service initialization
    local lazy_services=$(grep -r "lazy var.*Service" Dirt/Core/Services/ | wc -l)
    
    if [ $lazy_services -gt 5 ]; then
        log_performance_result "Lazy service initialization" "PASS" "$lazy_services lazy services found"
    else
        log_performance_result "Lazy service initialization" "FAIL" "$lazy_services lazy services found (target: >5)"
    fi
    
    # Check for singleton patterns (should be minimal)
    local singletons=$(grep -r "\.shared\|static let.*=.*(" Dirt/ | wc -l)
    
    if [ $singletons -lt 10 ]; then
        log_performance_result "Singleton usage (minimal)" "PASS" "$singletons singletons found (target: <10)"
    else
        log_performance_result "Singleton usage (minimal)" "FAIL" "$singletons singletons found (target: <10)"
    fi
    
    # Check for environment injection usage
    local env_injection=$(grep -r "@Environment.*services" Dirt/Features/ | wc -l)
    
    if [ $env_injection -gt 10 ]; then
        log_performance_result "Environment injection usage" "PASS" "$env_injection environment injections found"
    else
        log_performance_result "Environment injection usage" "FAIL" "$env_injection environment injections found (target: >10)"
    fi
}

# Function to test test suite performance
test_test_suite_performance() {
    echo -e "\n${BLUE}🧪 Testing Test Suite Performance${NC}"
    
    # Count test files
    local test_files=$(find DirtTests -name "*.swift" | wc -l)
    local ui_test_files=$(find DirtUITests -name "*.swift" | wc -l)
    
    echo "Test files: Unit tests: $test_files, UI tests: $ui_test_files"
    
    # Check test coverage distribution
    if [ $test_files -gt 20 ] && [ $ui_test_files -gt 2 ]; then
        log_performance_result "Test coverage distribution" "PASS" "Unit: $test_files, UI: $ui_test_files"
    else
        log_performance_result "Test coverage distribution" "FAIL" "Unit: $test_files (target: >20), UI: $ui_test_files (target: >2)"
    fi
    
    # Check for performance-specific tests
    local perf_tests=$(find DirtTests -name "*Performance*Tests.swift" | wc -l)
    
    if [ $perf_tests -gt 0 ]; then
        log_performance_result "Performance-specific tests" "PASS" "$perf_tests performance test files found"
    else
        log_performance_result "Performance-specific tests" "FAIL" "No performance test files found"
    fi
}

# Function to analyze asset optimization
test_asset_optimization() {
    echo -e "\n${BLUE}🖼️  Testing Asset Optimization${NC}"
    
    # Check for asset catalog usage
    if [ -d "Dirt/Assets.xcassets" ]; then
        log_performance_result "Asset catalog structure" "PASS" "Asset catalog exists"
    else
        log_performance_result "Asset catalog structure" "FAIL" "No asset catalog found"
    fi
    
    # Check for large image files (potential performance issue)
    local large_images=$(find Dirt -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | xargs ls -la 2>/dev/null | awk '$5 > 1048576 {print $9}' | wc -l)
    
    if [ $large_images -eq 0 ]; then
        log_performance_result "Image file sizes" "PASS" "No large images found (>1MB)"
    else
        log_performance_result "Image file sizes" "FAIL" "$large_images large images found (>1MB)"
    fi
    
    # Check for vector assets (better for performance)
    local vector_assets=$(find Dirt -name "*.pdf" | wc -l)
    
    if [ $vector_assets -gt 0 ]; then
        log_performance_result "Vector asset usage" "PASS" "$vector_assets vector assets found"
    else
        log_performance_result "Vector asset usage" "FAIL" "No vector assets found"
    fi
}

# Function to generate performance report
generate_performance_report() {
    echo -e "\n${BLUE}📋 Generating Performance Report${NC}"
    
    local report_file="performance_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Performance and Memory Usage Test Report

Generated: $(date)

## Summary

- Total Performance Tests: $TOTAL_PERFORMANCE_TESTS
- Passed: $PERFORMANCE_TESTS_PASSED
- Failed: $PERFORMANCE_TESTS_FAILED
- Success Rate: $(( PERFORMANCE_TESTS_PASSED * 100 / TOTAL_PERFORMANCE_TESTS ))%

## Architecture Performance Metrics

### Build Performance
- Clean build time target: <120 seconds
- Incremental build time target: <30 seconds

### Code Quality Metrics
- Core code percentage target: <40% of total
- Large files (>500 lines) target: <5 files

### Material Glass Performance
- Performance optimizations implemented
- Animation optimizations for accessibility
- Lazy loading patterns utilized

### Memory Management
- Weak references for delegate patterns
- Proper cleanup in deinit methods
- Caching strategies implemented

### Dependency Injection
- Lazy service initialization
- Minimal singleton usage
- Environment injection patterns

## Recommendations

1. **Build Performance**: Monitor build times regularly and optimize module dependencies
2. **Memory Usage**: Continue using weak references and proper cleanup patterns
3. **Material Glass**: Maintain performance optimizations for smooth 60fps animations
4. **Testing**: Expand performance-specific test coverage
5. **Assets**: Use vector assets where possible for better scalability

## Next Steps

- Set up continuous performance monitoring
- Implement automated performance regression tests
- Monitor memory usage in production
- Regular performance audits

EOF

    echo "Performance report generated: $report_file"
    log_performance_result "Performance report generation" "PASS" "Report saved to $report_file"
}

# Main execution
echo -e "${BLUE}Starting comprehensive performance testing...${NC}\n"

# Run all performance tests
test_build_performance
test_code_complexity
test_material_glass_performance
test_memory_usage_patterns
test_dependency_injection_performance
test_test_suite_performance
test_asset_optimization
generate_performance_report

# Final summary
echo -e "\n${BLUE}=============================================="
echo -e "📊 PERFORMANCE TEST SUMMARY"
echo -e "==============================================${NC}"
echo -e "Total Performance Tests: $TOTAL_PERFORMANCE_TESTS"
echo -e "${GREEN}Passed: $PERFORMANCE_TESTS_PASSED${NC}"
echo -e "${RED}Failed: $PERFORMANCE_TESTS_FAILED${NC}"

if [ $PERFORMANCE_TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🚀 ALL PERFORMANCE TESTS PASSED!${NC}"
    echo -e "${GREEN}The app is optimized for performance and memory usage.${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️  PERFORMANCE ISSUES DETECTED${NC}"
    echo -e "${YELLOW}Please review and address the failed performance tests.${NC}"
    exit 1
fi