#!/bin/bash

# Build Performance Measurement Script
# Measures build times and provides performance metrics for the refactored architecture

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Dirt"
SCHEME_NAME="Dirt"
BUILD_DIR="build_performance_logs"
ITERATIONS=3

echo -e "${BLUE}🏗️  Build Performance Measurement for ${PROJECT_NAME}${NC}"
echo "=================================================="

# Create build logs directory
mkdir -p "$BUILD_DIR"

# Function to measure build time
measure_build_time() {
    local build_type=$1
    local destination=$2
    local log_file="$BUILD_DIR/${build_type}_build_$(date +%Y%m%d_%H%M%S).log"
    
    echo -e "${YELLOW}📊 Measuring ${build_type} build time...${NC}"
    
    # Clean build directory first
    xcodebuild clean -scheme "$SCHEME_NAME" -destination "$destination" > /dev/null 2>&1 || true
    
    # Measure build time
    local start_time=$(date +%s.%N)
    
    if xcodebuild build -scheme "$SCHEME_NAME" -destination "$destination" > "$log_file" 2>&1; then
        local end_time=$(date +%s.%N)
        local build_time=$(echo "$end_time - $start_time" | bc -l)
        
        echo -e "${GREEN}✅ ${build_type} build completed in ${build_time}s${NC}"
        echo "$build_time"
    else
        echo -e "${RED}❌ ${build_type} build failed${NC}"
        echo "Build log saved to: $log_file"
        echo "0"
    fi
}

# Function to analyze build logs
analyze_build_logs() {
    local log_file=$1
    
    if [[ -f "$log_file" ]]; then
        echo -e "${BLUE}📈 Build Analysis:${NC}"
        
        # Count Swift compilation units
        local swift_files=$(grep -c "SwiftCompile" "$log_file" 2>/dev/null || echo "0")
        echo "  Swift files compiled: $swift_files"
        
        # Check for warnings
        local warnings=$(grep -c "warning:" "$log_file" 2>/dev/null || echo "0")
        echo "  Warnings: $warnings"
        
        # Check for errors
        local errors=$(grep -c "error:" "$log_file" 2>/dev/null || echo "0")
        echo "  Errors: $errors"
        
        # Extract compilation time for key files
        echo "  Key file compilation times:"
        grep -E "(PerformanceOptimizationService|ServiceContainer|GlassComponents)" "$log_file" | head -5 || echo "    No specific timing data found"
    fi
}

# Function to measure incremental build performance
measure_incremental_build() {
    echo -e "${YELLOW}🔄 Measuring incremental build performance...${NC}"
    
    # First, do a full build
    local destination="generic/platform=iOS"
    xcodebuild clean -scheme "$SCHEME_NAME" > /dev/null 2>&1 || true
    xcodebuild build -scheme "$SCHEME_NAME" -destination "$destination" > /dev/null 2>&1 || true
    
    # Touch a core file to trigger incremental build
    touch "Dirt/Core/Services/ServiceContainer.swift"
    
    local start_time=$(date +%s.%N)
    if xcodebuild build -scheme "$SCHEME_NAME" -destination "$destination" > /dev/null 2>&1; then
        local end_time=$(date +%s.%N)
        local incremental_time=$(echo "$end_time - $start_time" | bc -l)
        echo -e "${GREEN}✅ Incremental build completed in ${incremental_time}s${NC}"
        echo "$incremental_time"
    else
        echo -e "${RED}❌ Incremental build failed${NC}"
        echo "0"
    fi
}

# Function to check available destinations
check_destinations() {
    echo -e "${BLUE}🎯 Checking available build destinations...${NC}"
    
    # Try to find available destinations
    local destinations=$(xcodebuild -showdestinations -scheme "$SCHEME_NAME" 2>/dev/null | grep "platform:" | head -3)
    
    if [[ -n "$destinations" ]]; then
        echo "Available destinations:"
        echo "$destinations"
        
        # Return the first available destination
        echo "$destinations" | head -1 | sed 's/.*{ //' | sed 's/ }.*//'
    else
        echo "No destinations found, using generic iOS"
        echo "generic/platform=iOS"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting build performance measurement...${NC}"
    echo "Date: $(date)"
    echo "Xcode version: $(xcodebuild -version | head -1)"
    echo ""
    
    # Check if we can build
    local destination=$(check_destinations)
    echo "Using destination: $destination"
    echo ""
    
    # Array to store build times
    declare -a build_times=()
    
    # Measure multiple builds for average
    echo -e "${YELLOW}📊 Running $ITERATIONS build iterations...${NC}"
    for i in $(seq 1 $ITERATIONS); do
        echo "Iteration $i/$ITERATIONS"
        local build_time=$(measure_build_time "iteration_$i" "$destination")
        if [[ "$build_time" != "0" ]]; then
            build_times+=("$build_time")
        fi
        echo ""
    done
    
    # Calculate statistics
    if [[ ${#build_times[@]} -gt 0 ]]; then
        echo -e "${GREEN}📈 Build Performance Summary:${NC}"
        echo "================================"
        
        # Calculate average
        local total=0
        for time in "${build_times[@]}"; do
            total=$(echo "$total + $time" | bc -l)
        done
        local average=$(echo "scale=2; $total / ${#build_times[@]}" | bc -l)
        
        # Find min and max
        local min=${build_times[0]}
        local max=${build_times[0]}
        for time in "${build_times[@]}"; do
            if (( $(echo "$time < $min" | bc -l) )); then
                min=$time
            fi
            if (( $(echo "$time > $max" | bc -l) )); then
                max=$time
            fi
        done
        
        echo "Successful builds: ${#build_times[@]}/$ITERATIONS"
        echo "Average build time: ${average}s"
        echo "Fastest build: ${min}s"
        echo "Slowest build: ${max}s"
        
        # Performance assessment
        if (( $(echo "$average < 60" | bc -l) )); then
            echo -e "${GREEN}✅ Build performance: EXCELLENT (< 60s)${NC}"
        elif (( $(echo "$average < 120" | bc -l) )); then
            echo -e "${YELLOW}⚠️  Build performance: GOOD (< 120s)${NC}"
        elif (( $(echo "$average < 300" | bc -l) )); then
            echo -e "${YELLOW}⚠️  Build performance: ACCEPTABLE (< 300s)${NC}"
        else
            echo -e "${RED}❌ Build performance: NEEDS IMPROVEMENT (> 300s)${NC}"
        fi
        
        echo ""
        
        # Measure incremental build
        local incremental_time=$(measure_incremental_build)
        if [[ "$incremental_time" != "0" ]]; then
            echo "Incremental build time: ${incremental_time}s"
            
            if (( $(echo "$incremental_time < 10" | bc -l) )); then
                echo -e "${GREEN}✅ Incremental build performance: EXCELLENT (< 10s)${NC}"
            elif (( $(echo "$incremental_time < 30" | bc -l) )); then
                echo -e "${YELLOW}⚠️  Incremental build performance: GOOD (< 30s)${NC}"
            else
                echo -e "${RED}❌ Incremental build performance: NEEDS IMPROVEMENT (> 30s)${NC}"
            fi
        fi
        
    else
        echo -e "${RED}❌ No successful builds completed${NC}"
        exit 1
    fi
    
    # Analyze the latest build log
    local latest_log=$(ls -t "$BUILD_DIR"/*.log 2>/dev/null | head -1)
    if [[ -n "$latest_log" ]]; then
        echo ""
        analyze_build_logs "$latest_log"
    fi
    
    echo ""
    echo -e "${BLUE}📁 Build logs saved to: $BUILD_DIR${NC}"
    echo -e "${GREEN}🎉 Build performance measurement completed!${NC}"
}

# Check dependencies
if ! command -v bc &> /dev/null; then
    echo -e "${RED}❌ Error: 'bc' calculator is required but not installed${NC}"
    echo "Install with: brew install bc"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Error: 'xcodebuild' is required but not found${NC}"
    exit 1
fi

# Run main function
main "$@"