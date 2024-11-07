#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Array of project paths to build
PROJECTS=(
    "basics/counter/seahorse"
    "basics/hello-solana/seahorse"
    "basics/transfer-sol/seahorse"
    "oracles/pyth/seahorse"
)

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install Solana if not present
install_solana() {
    if ! command_exists solana; then
        echo -e "${YELLOW}Installing Solana...${NC}"
        sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
        export PATH="/home/runner/.local/share/solana/install/active_release/bin:$PATH"
        source "$HOME/.cargo/env"
        echo -e "${GREEN}Solana installed successfully${NC}"
    fi
    echo -e "${BLUE}Solana version:${NC}"
    solana -V
}

# Function to install system dependencies
install_system_deps() {
    echo -e "${YELLOW}Installing system dependencies...${NC}"
    sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo apt-get install -y pkg-config build-essential libudev-dev libssl-dev
    echo -e "${GREEN}System dependencies installed successfully${NC}"
}

# Function to install Rust and check version
check_rust() {
    if ! command_exists rustc; then
        echo -e "${YELLOW}Installing Rust...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    echo -e "${BLUE}Rust version:${NC}"
    rustc -V
}

# Function to install Anchor and AVM
install_anchor() {
    if ! command_exists avm; then
        echo -e "${YELLOW}Installing Anchor AVM...${NC}"
        cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
        echo -e "${GREEN}Anchor AVM installed successfully${NC}"
    fi

    echo -e "${YELLOW}Installing Anchor 0.27.0...${NC}"
    avm install 0.27.0
    avm use 0.27.0
    echo -e "${GREEN}Anchor 0.27.0 installed and set as active${NC}"
}

# Function to install Seahorse
install_seahorse() {
    if ! command_exists seahorse; then
        echo -e "${YELLOW}Installing Seahorse...${NC}"
        cargo install seahorse-lang
        echo -e "${GREEN}Seahorse installed successfully${NC}"
    fi
}

# Function to build projects
build_projects() {
    local failed=false

    for project in "${PROJECTS[@]}"; do
        echo -e "\n${YELLOW}Building $project...${NC}"
        if [ -d "$project" ]; then
            cd "$project" || exit 1
            if seahorse build; then
                echo -e "${GREEN}Successfully built $project${NC}"
            else
                echo -e "${RED}Failed to build $project${NC}"
                failed=true
            fi
            cd - > /dev/null || exit 1
        else
            echo -e "${RED}Project directory $project not found${NC}"
            failed=true
        fi
    done

    if [ "$failed" = true ]; then
        return 1
    fi
    return 0
}

# Main function
main() {
    echo -e "${YELLOW}=== Starting Seahorse Build Process ===${NC}"

    # Install all dependencies
    check_rust
    install_system_deps
    install_solana
    install_anchor
    install_seahorse

    echo -e "\n${YELLOW}=== Starting Project Builds ===${NC}"
    if build_projects; then
        echo -e "\n${GREEN}✓ All projects built successfully!${NC}"
        exit 0
    else
        echo -e "\n${RED}✗ Some projects failed to build${NC}"
        exit 1
    fi
}

# Run main function
main
