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

# Install dependencies for file-browser Vue.js subproject
echo ""
echo -e "${YELLOW}Installing dependencies for file-browser Vue.js project...${NC}"

FILE_BROWSER_DIR="subprojects/file-browser"

if [ -d "$FILE_BROWSER_DIR" ]; then
    if [ -f "$FILE_BROWSER_DIR/package.json" ]; then
        echo "Navigating to $FILE_BROWSER_DIR..."
        cd "$FILE_BROWSER_DIR"
        
        if [ "$USE_YARN" = true ]; then
            echo "Using yarn to install file-browser dependencies..."
            if yarn install; then
                echo -e "${GREEN}✓ File-browser dependencies installed successfully with yarn${NC}"
            else
                echo -e "${RED}Error: yarn install failed for file-browser.${NC}"
                cd ../..
                exit 1
            fi
        else
            echo "Using npm to install file-browser dependencies..."
            if npm install; then
                echo -e "${GREEN}✓ File-browser dependencies installed successfully with npm${NC}"
            else
                echo -e "${YELLOW}npm install failed, trying yarn as fallback...${NC}"
                if command -v yarn &> /dev/null; then
                    if yarn install; then
                        echo -e "${GREEN}✓ File-browser dependencies installed successfully with yarn${NC}"
                    else
                        echo -e "${RED}Error: Both npm and yarn installation failed for file-browser.${NC}"
                        cd ../..
                        exit 1
                    fi
                else
                    echo -e "${RED}Error: npm install failed and yarn is not available.${NC}"
                    cd ../..
                    exit 1
                fi
            fi
        fi
        
        # Verify Vue.js and Vite installation
        echo ""
        echo -e "${YELLOW}Verifying file-browser installation...${NC}"
        if [ -d "node_modules" ] && [ -d "node_modules/vue" ] && [ -d "node_modules/vite" ]; then
            echo -e "${GREEN}✓ Vue.js and Vite dependencies verified${NC}"
        else
            echo -e "${RED}Warning: Some file-browser dependencies may be missing.${NC}"
        fi
        
        # Return to project root
        cd ../..
    else
        echo -e "${YELLOW}Warning: package.json not found in $FILE_BROWSER_DIR${NC}"
    fi
else
    echo -e "${YELLOW}Warning: $FILE_BROWSER_DIR directory not found. Skipping file-browser setup.${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To start the main service, run:"
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
echo "To start the file-browser Vue.js app:"
echo -e "  ${YELLOW}cd subprojects/file-browser${NC}"
echo -e "  ${YELLOW}npm start${NC}  # Production mode (serves on port 3001)"
echo ""
echo "Or for development mode (with hot reload):"
echo -e "  ${YELLOW}cd subprojects/file-browser${NC}"
echo -e "  ${YELLOW}npm run dev:full${NC}  # Runs both backend and Vite dev server"
echo ""
echo "File-browser will be available at:"
echo "  - Development: http://localhost:5173 (Vite dev server)"
echo "  - Production: http://localhost:3001"
echo ""

