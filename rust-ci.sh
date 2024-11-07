#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check required tools
check_requirements() {
    echo -e "${BLUE}Checking Rust toolchain requirements...${NC}"

    # Check if rustc is installed
    if ! command -v rustc &> /dev/null; then
        echo -e "${RED}Rust is not installed. Please install Rust using:${NC}"
        echo -e "${YELLOW}curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh${NC}"
        exit 1
    fi

    # Check for cargo
    if ! command -v cargo &> /dev/null; then
        echo -e "${RED}Cargo is not installed. Please install Rust using:${NC}"
        echo -e "${YELLOW}curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh${NC}"
        exit 1
    fi

    # Check for rustfmt
    if ! command -v rustfmt &> /dev/null; then
        echo -e "${BLUE}Installing rustfmt...${NC}"
        rustup component add rustfmt
    fi

    # Check for clippy
    if ! command -v clippy-driver &> /dev/null; then
        echo -e "${BLUE}Installing clippy...${NC}"
        rustup component add clippy
    fi
}

# Function to run tests
run_tests() {
    echo -e "\n${BLUE}Running tests...${NC}"
    if cargo test; then
        echo -e "${GREEN}✓ Tests passed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Tests failed${NC}"
        return 1
    fi
}

# Function to check formatting
check_formatting() {
    echo -e "\n${BLUE}Checking code formatting...${NC}"
    if cargo fmt --check; then
        echo -e "${GREEN}✓ Code formatting is correct${NC}"
        return 0
    else
        echo -e "${RED}✗ Code formatting issues found${NC}"
        echo -e "${YELLOW}Run 'cargo fmt' to fix formatting issues${NC}"
        return 1
    fi
}

# Function to run clippy
run_clippy() {
    echo -e "\n${BLUE}Running Clippy lints...${NC}"
    if cargo clippy -- -D warnings; then
        echo -e "${GREEN}✓ Clippy checks passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Clippy found issues${NC}"
        return 1
    fi
}

# Function to run all checks
run_all() {
    local failed=0

    run_tests
    failed=$((failed + $?))

    check_formatting
    failed=$((failed + $?))

    run_clippy
    failed=$((failed + $?))

    if [ $failed -eq 0 ]; then
        echo -e "\n${GREEN}✓ All checks passed successfully!${NC}"
        return 0
    else
        echo -e "\n${RED}✗ Some checks failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    check_requirements

    echo -e "${BLUE}Select check to run:${NC}"
    echo "1. Run tests only"
    echo "2. Check formatting only"
    echo "3. Run clippy only"
    echo "4. Run all checks"
    read -r choice

    case $choice in
        1)
            run_tests
            ;;
        2)
            check_formatting
            ;;
        3)
            run_clippy
            ;;
        4)
            run_all
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# Run main function
main
