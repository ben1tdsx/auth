#!/bin/bash

# Start script for File Browser with Cookie Manager
# This script starts both the cookie manager and the file-browser Vue.js app

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Main project directory (where this script is located - root level)
MAIN_DIR="$SCRIPT_DIR"
# File browser directory (subproject)
FILE_BROWSER_DIR="$SCRIPT_DIR/subprojects/file-browser"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting File Browser Services${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed.${NC}"
    exit 1
fi

# Configuration
AUTH_SERVICE_URL="${AUTH_SERVICE_URL:-http://localhost:3000}"
COOKIE_MANAGER_PORT="${COOKIE_MANAGER_PORT:-3000}"
FILE_BROWSER_PORT="${PORT:-3001}"
VITE_PORT="${VITE_PORT:-5173}"

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Cookie Manager: ${AUTH_SERVICE_URL}"
echo -e "  File Browser Backend: http://localhost:${FILE_BROWSER_PORT}"
echo -e "  Vite Dev Server: http://localhost:${VITE_PORT}"
echo ""

# Function to cleanup background processes on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down services...${NC}"
    if [ ! -z "$COOKIE_MANAGER_PID" ]; then
        echo -e "${YELLOW}Stopping cookie manager (PID: $COOKIE_MANAGER_PID)...${NC}"
        kill $COOKIE_MANAGER_PID 2>/dev/null || true
    fi
    if [ ! -z "$FILE_BROWSER_PID" ]; then
        echo -e "${YELLOW}Stopping file browser services (PID: $FILE_BROWSER_PID)...${NC}"
        kill $FILE_BROWSER_PID 2>/dev/null || true
        # Kill child processes (concurrently spawns multiple processes)
        pkill -P $FILE_BROWSER_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}Cleanup complete.${NC}"
    exit 0
}

# Set up signal handlers for cleanup
trap cleanup SIGINT SIGTERM

# Check if cookie manager is already running
if lsof -Pi :${COOKIE_MANAGER_PORT} -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}Cookie manager appears to be already running on port ${COOKIE_MANAGER_PORT}${NC}"
    echo -e "${YELLOW}Skipping cookie manager startup...${NC}"
else
    # Start cookie manager
    echo -e "${BLUE}Starting cookie manager...${NC}"
    cd "$MAIN_DIR"
    
    if [ ! -f "package.json" ]; then
        echo -e "${RED}Error: package.json not found in main project directory: $MAIN_DIR${NC}"
        exit 1
    fi
    
    # Start cookie manager in background
    PORT=${COOKIE_MANAGER_PORT} npm start > /tmp/cookie-manager.log 2>&1 &
    COOKIE_MANAGER_PID=$!
    echo -e "${GREEN}✓ Cookie manager started (PID: $COOKIE_MANAGER_PID)${NC}"
    echo -e "  Logs: tail -f /tmp/cookie-manager.log"
    
    # Wait a moment for the cookie manager to start
    sleep 2
    
    # Check if it's actually running
    if ! kill -0 $COOKIE_MANAGER_PID 2>/dev/null; then
        echo -e "${RED}Error: Cookie manager failed to start${NC}"
        echo -e "${YELLOW}Check logs: cat /tmp/cookie-manager.log${NC}"
        exit 1
    fi
fi

# Start file browser services
echo ""
echo -e "${BLUE}Starting file browser services...${NC}"
cd "$FILE_BROWSER_DIR"

if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: package.json not found in file-browser directory: $FILE_BROWSER_DIR${NC}"
    cleanup
    exit 1
fi

# Start file browser with dev:full (which starts both backend and Vite)
AUTH_SERVICE_URL=${AUTH_SERVICE_URL} npm run dev:full &
FILE_BROWSER_PID=$!
echo -e "${GREEN}✓ File browser services started (PID: $FILE_BROWSER_PID)${NC}"
echo ""

# Wait a moment for services to start
sleep 3

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All services are running!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Services:${NC}"
echo -e "  Cookie Manager:     ${AUTH_SERVICE_URL}"
echo -e "  File Browser API:   http://localhost:${FILE_BROWSER_PORT}"
echo -e "  Vite Dev Server:    http://localhost:${VITE_PORT}"
echo ""
echo -e "${YELLOW}Access the application at:${NC}"
echo -e "  ${GREEN}http://localhost:${VITE_PORT}/login${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

# Wait for the file browser process (this will block until it exits)
wait $FILE_BROWSER_PID

# If we get here, the file browser exited, so cleanup
cleanup

