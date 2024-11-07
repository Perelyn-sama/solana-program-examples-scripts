#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check required dependencies
check_dependencies() {
    if ! command -v biome &> /dev/null; then
        echo -e "${RED}Error: Biome is not installed${NC}"
        echo "Please install Biome using npm:"
        echo "  npm install --global @biomejs/biome"
        exit 1
    fi
}

# Function to check if biome.json exists
check_biome_config() {
    if [ ! -f "biome.json" ]; then
        echo -e "${RED}Error: biome.json configuration file not found${NC}"
        echo "Please create a biome.json configuration file in the project root."
        exit 1
    fi
}

# Function to run Biome checks
run_biome_checks() {
    echo -e "${YELLOW}Running Biome code quality checks...${NC}"

    if biome ci ./ --config-path biome.json; then
        echo -e "${GREEN}✓ Biome checks passed successfully!${NC}"
        return 0
    else
        echo -e "${RED}✗ Biome checks failed${NC}"
        return 1
    fi
}

main() {
    echo -e "${YELLOW}=== TypeScript Code Quality Check ===${NC}"

    # Check for required dependencies
    check_dependencies

    # Check for Biome configuration
    check_biome_config

    # Run Biome checks
    run_biome_checks
    exit_code=$?

    # Print final status
    if [ $exit_code -eq 0 ]; then
        echo -e "\n${GREEN}All code quality checks passed!${NC}"
    else
        echo -e "\n${RED}Code quality checks failed. Please fix the issues above.${NC}"
    fi

    exit $exit_code
}

# Run main function
main
