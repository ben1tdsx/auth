#!/bin/bash

# Setup script for Node.js Cookie Session Manager
# This script installs dependencies and prepares the service for running

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Node.js Cookie Session Manager Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Node.js is installed
echo -e "${YELLOW}Checking for Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed.${NC}"
    echo "Please install Node.js (v14 or higher) first:"
    echo "  Ubuntu/Debian: sudo apt-get update && sudo apt-get install nodejs npm"
    echo "  Or use nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    exit 1
fi

NODE_VERSION=$(node --version)
echo -e "${GREEN}✓ Node.js found: ${NODE_VERSION}${NC}"

# Check Node.js version (should be v14 or higher)
NODE_MAJOR_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_MAJOR_VERSION" -lt 14 ]; then
    echo -e "${RED}Warning: Node.js version should be v14 or higher. Current: ${NODE_VERSION}${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for package manager (npm or yarn)
echo ""
echo -e "${YELLOW}Checking for package manager...${NC}"
USE_YARN=false

if command -v yarn &> /dev/null; then
    YARN_VERSION=$(yarn --version)
    echo -e "${GREEN}✓ Yarn found: ${YARN_VERSION}${NC}"
    USE_YARN=true
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓ npm found: ${NPM_VERSION}${NC}"
else
    if [ "$USE_YARN" = false ]; then
        echo -e "${RED}Error: Neither npm nor yarn is installed.${NC}"
        echo "Please install npm: sudo apt-get install npm"
        exit 1
    fi
fi

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: package.json not found in current directory.${NC}"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Check if users.json exists
if [ ! -f "users.json" ]; then
    echo -e "${YELLOW}Warning: users.json not found. Creating default users.json...${NC}"
    cat > users.json << 'EOF'
{
  "admin": "password123",
  "user1": "secret456",
  "testuser": "testpass789"
}
EOF
    echo -e "${GREEN}✓ Created users.json with default users${NC}"
fi

# Install dependencies
echo ""
echo -e "${YELLOW}Installing dependencies...${NC}"

if [ "$USE_YARN" = true ]; then
    echo "Using yarn to install dependencies..."
    if yarn install; then
        echo -e "${GREEN}✓ Dependencies installed successfully with yarn${NC}"
    else
        echo -e "${RED}Error: yarn install failed.${NC}"
        exit 1
    fi
else
    echo "Using npm to install dependencies..."
    if npm install; then
        echo -e "${GREEN}✓ Dependencies installed successfully with npm${NC}"
    else
        echo -e "${YELLOW}npm install failed, trying yarn as fallback...${NC}"
        if command -v yarn &> /dev/null; then
            if yarn install; then
                echo -e "${GREEN}✓ Dependencies installed successfully with yarn${NC}"
            else
                echo -e "${RED}Error: Both npm and yarn installation failed.${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Error: npm install failed and yarn is not available.${NC}"
            exit 1
        fi
    fi
fi

# Verify installation
echo ""
echo -e "${YELLOW}Verifying installation...${NC}"
if [ -d "node_modules" ] && [ -d "node_modules/express" ] && [ -d "node_modules/cookie-parser" ]; then
    echo -e "${GREEN}✓ All dependencies verified${NC}"
else
    echo -e "${RED}Warning: Some dependencies may be missing.${NC}"
fi

# Check if index.js exists
if [ ! -f "index.js" ]; then
    echo -e "${RED}Error: index.js not found.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To start the service, run:"
echo -e "  ${YELLOW}npm start${NC}"
echo ""
echo "Or for development with auto-reload:"
echo -e "  ${YELLOW}npm run dev${NC}"
echo ""
echo "The service will run on port 3000 by default."
echo "You can change the port by setting the PORT environment variable:"
echo -e "  ${YELLOW}PORT=8080 npm start${NC}"
echo ""
echo "Available endpoints:"
echo "  - Health check: http://localhost:3000/health"
echo "  - Login: http://localhost:3000/login"
echo "  - Protected: http://localhost:3000/protected"
echo "  - Auth validation: http://localhost:3000/auth/validate"
echo ""

