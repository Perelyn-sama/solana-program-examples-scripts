#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NODE_VERSION="20.x"
SOLANA_VERSIONS=("1.18.17" "stable")

# Function to check dependencies
check_dependencies() {
    local missing_deps=()

    for cmd in node npm rustc solana pnpm; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Function to get native projects
get_projects() {
    if [ -f ".github/.ghaignore" ]; then
        find . -type d -name "native" | grep -v -f <(grep . .github/.ghaignore | grep -v '^$')
    else
        find . -type d -name "native"
    fi
}

# Function to build projects
build_projects() {
    local failed=false
    local failed_builds=()

    echo -e "\n${YELLOW}=== Building Native Programs ===${NC}"

    # Get all project directories
    mapfile -t ProjectDirs < <(get_projects)

    echo -e "${BLUE}Projects to Build:${NC}"
    printf "%s\n" "${ProjectDirs[@]}"

    for projectDir in "${ProjectDirs[@]}"; do
        echo -e "\n${YELLOW}********${NC}"
        echo -e "${YELLOW}Building $projectDir${NC}"
        echo -e "${YELLOW}********${NC}"

        cd "$projectDir" || continue

        if pnpm build; then
            echo -e "${GREEN}Build succeeded for $projectDir${NC}"
        else
            failed=true
            failed_builds+=("$projectDir")
            echo -e "${RED}Build failed for $projectDir${NC}"
        fi

        cd - > /dev/null || exit 1
    done

    if [ "$failed" = true ]; then
        echo -e "\n${RED}Programs that failed building:${NC}"
        printf "%s\n" "${failed_builds[@]}"
        return 1
    else
        echo -e "\n${GREEN}All programs built successfully.${NC}"
        return 0
    fi
}

# Function to test projects
test_projects() {
    local solana_version=$1
    local failed=false
    local failed_tests=()

    echo -e "\n${YELLOW}=== Testing Native Programs (Solana $solana_version) ===${NC}"

    # Get all project directories
    mapfile -t ProjectDirs < <(get_projects)

    echo -e "${BLUE}Projects to Test:${NC}"
    printf "%s\n" "${ProjectDirs[@]}"

    echo -e "${BLUE}Versions:${NC}"
    solana -V
    rustc -V

    for projectDir in "${ProjectDirs[@]}"; do
        echo -e "\n${YELLOW}********${NC}"
        echo -e "${YELLOW}Testing $projectDir${NC}"
        echo -e "${YELLOW}********${NC}"

        cd "$projectDir" || continue

        echo "Installing dependencies..."
        if ! pnpm install --frozen-lockfile; then
            echo -e "${RED}Failed to install dependencies for $projectDir${NC}"
            failed=true
            failed_tests+=("$projectDir")
            cd - > /dev/null || exit 1
            continue
        fi

        if pnpm build-and-test; then
            echo -e "${GREEN}Tests succeeded for $projectDir${NC}"
        else
            failed=true
            failed_tests+=("$projectDir")
            echo -e "${RED}Tests failed for $projectDir${NC}"
        fi

        cd - > /dev/null || exit 1
    done

    if [ "$failed" = true ]; then
        echo -e "\n${RED}Programs that failed testing:${NC}"
        printf "%s\n" "${failed_tests[@]}"
        return 1
    else
        echo -e "\n${GREEN}All tests passed.${NC}"
        return 0
    fi
}

main() {
    echo -e "${YELLOW}=== Native Solana Programs Workflow ===${NC}"

    # Check dependencies
    check_dependencies

    # Build phase
    if ! build_projects; then
        echo -e "${RED}Build phase failed${NC}"
        exit 1
    fi

    # Test phase with multiple Solana versions
    local test_failed=false
    for solana_version in "${SOLANA_VERSIONS[@]}"; do
        echo -e "\n${YELLOW}Switching to Solana version: $solana_version${NC}"

        if [ "$solana_version" != "stable" ]; then
            solana-install init "$solana_version"
        else
            solana-install init stable
        fi

        if ! test_projects "$solana_version"; then
            test_failed=true
        fi
    done

    if [ "$test_failed" = true ]; then
        echo -e "\n${RED}Test phase failed${NC}"
        exit 1
    fi

    echo -e "\n${GREEN}All builds and tests completed successfully!${NC}"
}

# Run main function
main
