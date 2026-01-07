#!/bin/bash
# Test script for Brainery installation
# Tests all containers and MCP connectivity

set -e

echo "🧪 Brainery Installation Test"
echo "=============================="
echo

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0

# Function to print test result
test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAILED++))
    fi
}

# Test 1: Docker is running
echo "Test 1: Docker daemon"
if docker info > /dev/null 2>&1; then
    test_result 0 "Docker is running"
else
    test_result 1 "Docker is not running"
    echo "Please start Docker Desktop and try again."
    exit 1
fi
echo

# Test 2: Check if containers are running
echo "Test 2: Container status"
CONTAINERS=("brainery-crawl4ai-1" "brainery-yt-dlp-server-1" "brainery-whisper-server-1" "brainery-anythingllm-1")

for container in "${CONTAINERS[@]}"; do
    if docker ps --filter "name=${container}" --filter "status=running" | grep -q "${container}"; then
        test_result 0 "Container ${container} is running"
    else
        test_result 1 "Container ${container} is not running"
    fi
done
echo

# Test 3: Health endpoints
echo "Test 3: Service health checks"

# Crawl4AI
if curl -s http://localhost:9100/health | grep -q "ok"; then
    test_result 0 "Crawl4AI health check (port 9100)"
else
    test_result 1 "Crawl4AI health check (port 9100)"
fi

# yt-dlp-server
if curl -s http://localhost:9101/health | grep -q "ok"; then
    test_result 0 "yt-dlp-server health check (port 9101)"
else
    test_result 1 "yt-dlp-server health check (port 9101)"
fi

# whisper-server
if curl -s http://localhost:9102/health | grep -q "ok"; then
    test_result 0 "Whisper-server health check (port 9102)"
else
    test_result 1 "Whisper-server health check (port 9102)"
fi

# AnythingLLM
if curl -s http://localhost:9103/api/ping | grep -q "pong"; then
    test_result 0 "AnythingLLM API check (port 9103)"
else
    test_result 1 "AnythingLLM API check (port 9103)"
fi
echo

# Test 4: Check volumes
echo "Test 4: Docker volumes"
VOLUMES=("anythingllm-storage" "whisper-models")

for volume in "${VOLUMES[@]}"; do
    if docker volume ls | grep -q "${volume}"; then
        test_result 0 "Volume ${volume} exists"
    else
        test_result 1 "Volume ${volume} not found"
    fi
done
echo

# Test 5: Port availability
echo "Test 5: Port conflicts"
PORTS=(9100 9101 9102 9103)

for port in "${PORTS[@]}"; do
    if lsof -i :${port} > /dev/null 2>&1 || netstat -an | grep -q ":${port}"; then
        test_result 0 "Port ${port} is in use (expected)"
    else
        test_result 1 "Port ${port} is not in use (unexpected)"
    fi
done
echo

# Test 6: Skill installation
echo "Test 6: Skill files"
SKILL_DIR="${HOME}/.claude/skills/brainery"

if [ -d "${SKILL_DIR}" ]; then
    test_result 0 "Skill directory exists at ${SKILL_DIR}"

    if [ -f "${SKILL_DIR}/prompt.md" ]; then
        test_result 0 "prompt.md found"
    else
        test_result 1 "prompt.md not found"
    fi

    if [ -f "${SKILL_DIR}/.claude-plugin/plugin.json" ]; then
        test_result 0 "plugin.json found"
    else
        test_result 1 "plugin.json not found"
    fi
else
    test_result 1 "Skill directory not found at ${SKILL_DIR}"
    echo -e "${YELLOW}Note:${NC} Install skill with: git clone https://github.com/Tapiocapioca/brainery.git ${SKILL_DIR}"
fi
echo

# Summary
echo "=============================="
echo "📊 Test Summary"
echo "=============================="
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo

if [ ${FAILED} -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC} Brainery is ready to use."
    exit 0
else
    echo -e "${RED}✗ Some tests failed.${NC} Please check the errors above."
    echo
    echo "Troubleshooting:"
    echo "1. Ensure Docker containers are running: docker-compose up -d"
    echo "2. Check container logs: docker-compose logs <service-name>"
    echo "3. Verify port availability: netstat -an | grep 910[0-3]"
    echo "4. See installation guide: https://github.com/Tapiocapioca/brainery/blob/master/docs/en/installation.md"
    exit 1
fi
