#!/bin/bash

# Configuration
MAX_JOBS=64
MIN_PROJECTS_PER_JOB=4
MIN_PROJECTS_FOR_MATRIX=4

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check required dependencies
check_dependencies() {
    local missing_deps=()

    # Check for required commands
    for cmd in find grep tr sed jq solana anchor pnpm; do
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

# Function to build and test a single project
build_and_test() {
    local project=$1
    local failed_projects_file=$2

    echo -e "\n${YELLOW}Building and Testing $project${NC}"
    cd "$project" || return 1

    # Run anchor build
    if ! anchor build; then
        echo -e "${RED}Error: anchor build failed for $project${NC}"
        echo "$project: anchor build failed" >> "$failed_projects_file"
        rm -rf target
        cd - > /dev/null
        return 1
    fi

    # Install dependencies
    if ! pnpm install --frozen-lockfile; then
        echo -e "${RED}Error: pnpm install failed for $project${NC}"
        echo "$project: pnpm install failed" >> "$failed_projects_file"
        cd - > /dev/null
        return 1
    fi

    # Run anchor test
    if ! anchor test; then
        echo -e "${RED}Error: anchor test failed for $project${NC}"
        echo "$project: anchor test failed" >> "$failed_projects_file"
        rm -rf target node_modules
        cd - > /dev/null
        return 1
    fi

    echo -e "${GREEN}Build and tests succeeded for $project${NC}"
    rm -rf target node_modules
    cd - > /dev/null
    return 0
}

# Function to get all anchor projects
get_projects() {
    # Generate ignore pattern from .github/.ghaignore if it exists
    local ignore_pattern=""
    if [ -f ".github/.ghaignore" ]; then
        ignore_pattern=$(grep -v '^#' .github/.ghaignore | grep -v '^$' | tr '\n' '|' | sed 's/|$//')
    fi

    if [ -n "$ignore_pattern" ]; then
        find . -type d -name "anchor" | grep -vE "$ignore_pattern" | sort
    else
        find . -type d -name "anchor" | sort
    fi
}

# Function to print summary
print_summary() {
    local total_projects=$1
    local failed_projects_file=$2

    echo -e "\n${YELLOW}=== Anchor Workflow Summary ===${NC}"
    echo "Total projects processed: $total_projects"

    if [ -f "$failed_projects_file" ] && [ -s "$failed_projects_file" ]; then
        echo -e "\n${RED}Failed projects:${NC}"
        cat "$failed_projects_file"
        return 1
    else
        echo -e "\n${GREEN}All builds and tests passed!${NC}"
        return 0
    fi
}

main() {
    # Check dependencies first
    check_dependencies

    # Create temporary file for failed projects
    local failed_projects_file=$(mktemp)

    # Get all projects into an array
    local projects=()
    while IFS= read -r project; do
        projects+=("$project")
    done < <(get_projects)

    local total_projects=${#projects[@]}

    if [ "$total_projects" -eq 0 ]; then
        echo "No projects found to build and test."
        exit 0
    fi

    echo "Found $total_projects projects to process"

    # Process all projects
    local failed=false
    for project in "${projects[@]}"; do
        if ! build_and_test "$project" "$failed_projects_file"; then
            failed=true
        fi
    done

    # Print summary and exit with appropriate status
    print_summary "$total_projects" "$failed_projects_file"
    exit_code=$?

    # Cleanup
    rm -f "$failed_projects_file"

    exit $exit_code
}

# Run main function
main
