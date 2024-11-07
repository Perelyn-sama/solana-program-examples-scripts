#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check required tools
check_requirements() {
    echo -e "${BLUE}Checking requirements...${NC}"

    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}Node.js is not installed. Please install Node.js 20.x${NC}"
        exit 1
    fi

    # Check pnpm
    if ! command -v pnpm &> /dev/null; then
        echo -e "${BLUE}Installing pnpm...${NC}"
        npm install --global pnpm
    fi

    # Check Solana
    if ! command -v solana &> /dev/null; then
        echo -e "${RED}Solana CLI is not installed. Please install Solana${NC}"
        exit 1
    fi

    # Check Rust
    if ! command -v rustc &> /dev/null; then
        echo -e "${RED}Rust is not installed. Please install Rust${NC}"
        exit 1
    fi
}

# Function to find valid project directories
find_project_dirs() {
    # Find all steel directories but exclude common directories to ignore
    if [ -f .github/.ghaignore ]; then
        # Use .ghaignore if it exists
        ProjectDirs=($(find . -type d -name "steel" \
            ! -path "*/.git/*" \
            ! -path "*/node_modules/*" \
            ! -path "*/target/*" \
            ! -path "*/dist/*" \
            | grep -v -f <(grep . .github/.ghaignore | grep -v '^$')))
    else
        # Default ignore patterns
        ProjectDirs=($(find . -type d -name "steel" \
            ! -path "*/.git/*" \
            ! -path "*/node_modules/*" \
            ! -path "*/target/*" \
            ! -path "*/dist/*"))
    fi
}

# Function to build projects
build_projects() {
    echo -e "${BLUE}Starting build process...${NC}"

    find_project_dirs

    if [ ${#ProjectDirs[@]} -eq 0 ]; then
        echo -e "${RED}No valid steel directories found${NC}"
        return 1
    }

    echo -e "${BLUE}Projects to Build:${NC}"
    printf "%s\n" "${ProjectDirs[@]}"

    failed=false
    failed_builds=()

    for projectDir in "${ProjectDirs[@]}"; do
        echo -e "\n${BLUE}********${NC}"
        echo -e "${BLUE}Building $projectDir${NC}"
        echo -e "${BLUE}********${NC}"

        if [ ! -f "$projectDir/package.json" ]; then
            echo -e "${RED}Skipping $projectDir - no package.json found${NC}"
            continue
        }

        cd "$projectDir" || continue

        if pnpm build; then
            echo -e "${GREEN}Build succeeded for $projectDir.${NC}"
        else
            failed=true
            failed_builds+=("$projectDir")
            echo -e "${RED}Build failed for $projectDir. Continuing with the next program.${NC}"
        fi

        cd - > /dev/null || exit
    done

    if [ "$failed" = true ]; then
        echo -e "${RED}Programs that failed building:${NC}"
        printf "%s\n" "${failed_builds[@]}"
        return 1
    else
        echo -e "${GREEN}All programs built successfully.${NC}"
        return 0
    fi
}

# Function to run tests
run_tests() {
    echo -e "${BLUE}Starting test process...${NC}"
    echo -e "${BLUE}Solana version: $(solana -V)${NC}"
    echo -e "${BLUE}Rust version: $(rustc -V)${NC}"

    find_project_dirs

    if [ ${#ProjectDirs[@]} -eq 0 ]; then
        echo -e "${RED}No valid steel directories found${NC}"
        return 1
    }

    echo -e "${BLUE}Projects to Test:${NC}"
    printf "%s\n" "${ProjectDirs[@]}"

    failed=false
    failed_tests=()

    for projectDir in "${ProjectDirs[@]}"; do
        echo -e "\n${BLUE}********${NC}"
        echo -e "${BLUE}Testing $projectDir${NC}"
        echo -e "${BLUE}********${NC}"

        if [ ! -f "$projectDir/package.json" ]; then
            echo -e "${RED}Skipping $projectDir - no package.json found${NC}"
            continue
        }

        cd "$projectDir" || continue

        pnpm install --frozen-lockfile
        if pnpm build-and-test; then
            echo -e "${GREEN}Tests succeeded for $projectDir.${NC}"
        else
            failed=true
            failed_tests+=("$projectDir")
            echo -e "${RED}Tests failed for $projectDir. Continuing with the next program.${NC}"
        fi

        cd - > /dev/null || exit
    done

    if [ "$failed" = true ]; then
        echo -e "${RED}*****************************${NC}"
        echo -e "${RED}Programs that failed testing:${NC}"
        printf "%s\n" "${failed_tests[@]}"
        return 1
    else
        echo -e "${GREEN}All tests passed.${NC}"
        return 0
    fi
}

# Main execution
main() {
    check_requirements

    echo -e "${BLUE}Select operation:${NC}"
    echo "1. Build only"
    echo "2. Test only"
    echo "3. Build and test"
    read -r choice

    case $choice in
        1)
            build_projects
            ;;
        2)
            run_tests
            ;;
        3)
            build_projects && run_tests
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# Run main function
main
