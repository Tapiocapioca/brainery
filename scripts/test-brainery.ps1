# Test script for Brainery installation (PowerShell)
# Tests all containers and MCP connectivity

Write-Host "🧪 Brainery Installation Test" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

$PASSED = 0
$FAILED = 0

# Function to print test result
function Test-Result {
    param (
        [bool]$Success,
        [string]$Message
    )
    if ($Success) {
        Write-Host "✓ PASS: $Message" -ForegroundColor Green
        $script:PASSED++
    } else {
        Write-Host "✗ FAIL: $Message" -ForegroundColor Red
        $script:FAILED++
    }
}

# Test 1: Docker is running
Write-Host "Test 1: Docker daemon"
try {
    docker info | Out-Null
    Test-Result -Success $true -Message "Docker is running"
} catch {
    Test-Result -Success $false -Message "Docker is not running"
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Test 2: Check if containers are running
Write-Host "Test 2: Container status"
$containers = @("brainery-crawl4ai-1", "brainery-yt-dlp-server-1", "brainery-whisper-server-1", "brainery-anythingllm-1")

foreach ($container in $containers) {
    $running = docker ps --filter "name=$container" --filter "status=running" --format "{{.Names}}"
    if ($running -match $container) {
        Test-Result -Success $true -Message "Container $container is running"
    } else {
        Test-Result -Success $false -Message "Container $container is not running"
    }
}
Write-Host ""

# Test 3: Health endpoints
Write-Host "Test 3: Service health checks"

# Crawl4AI
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9100/health" -UseBasicParsing -ErrorAction Stop
    if ($response.Content -match "ok") {
        Test-Result -Success $true -Message "Crawl4AI health check (port 9100)"
    } else {
        Test-Result -Success $false -Message "Crawl4AI health check (port 9100)"
    }
} catch {
    Test-Result -Success $false -Message "Crawl4AI health check (port 9100)"
}

# yt-dlp-server
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9101/health" -UseBasicParsing -ErrorAction Stop
    if ($response.Content -match "ok") {
        Test-Result -Success $true -Message "yt-dlp-server health check (port 9101)"
    } else {
        Test-Result -Success $false -Message "yt-dlp-server health check (port 9101)"
    }
} catch {
    Test-Result -Success $false -Message "yt-dlp-server health check (port 9101)"
}

# whisper-server
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9102/health" -UseBasicParsing -ErrorAction Stop
    if ($response.Content -match "ok") {
        Test-Result -Success $true -Message "Whisper-server health check (port 9102)"
    } else {
        Test-Result -Success $false -Message "Whisper-server health check (port 9102)"
    }
} catch {
    Test-Result -Success $false -Message "Whisper-server health check (port 9102)"
}

# AnythingLLM
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9103/api/ping" -UseBasicParsing -ErrorAction Stop
    if ($response.Content -match "pong") {
        Test-Result -Success $true -Message "AnythingLLM API check (port 9103)"
    } else {
        Test-Result -Success $false -Message "AnythingLLM API check (port 9103)"
    }
} catch {
    Test-Result -Success $false -Message "AnythingLLM API check (port 9103)"
}
Write-Host ""

# Test 4: Check volumes
Write-Host "Test 4: Docker volumes"
$volumes = @("anythingllm-storage", "whisper-models")

foreach ($volume in $volumes) {
    $exists = docker volume ls --format "{{.Name}}" | Select-String -Pattern $volume
    if ($exists) {
        Test-Result -Success $true -Message "Volume $volume exists"
    } else {
        Test-Result -Success $false -Message "Volume $volume not found"
    }
}
Write-Host ""

# Test 5: Port availability
Write-Host "Test 5: Port conflicts"
$ports = @(9100, 9101, 9102, 9103)

foreach ($port in $ports) {
    $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connections) {
        Test-Result -Success $true -Message "Port $port is in use (expected)"
    } else {
        Test-Result -Success $false -Message "Port $port is not in use (unexpected)"
    }
}
Write-Host ""

# Test 6: Skill installation
Write-Host "Test 6: Skill files"
$skillDir = "$HOME\.claude\skills\brainery"

if (Test-Path $skillDir) {
    Test-Result -Success $true -Message "Skill directory exists at $skillDir"

    if (Test-Path "$skillDir\prompt.md") {
        Test-Result -Success $true -Message "prompt.md found"
    } else {
        Test-Result -Success $false -Message "prompt.md not found"
    }

    if (Test-Path "$skillDir\.claude-plugin\plugin.json") {
        Test-Result -Success $true -Message "plugin.json found"
    } else {
        Test-Result -Success $false -Message "plugin.json not found"
    }
} else {
    Test-Result -Success $false -Message "Skill directory not found at $skillDir"
    Write-Host "Note: Install skill with: git clone https://github.com/Tapiocapioca/brainery.git $skillDir" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "📊 Test Summary" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "Passed: $PASSED" -ForegroundColor Green
Write-Host "Failed: $FAILED" -ForegroundColor Red
Write-Host ""

if ($FAILED -eq 0) {
    Write-Host "✓ All tests passed! Brainery is ready to use." -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Some tests failed. Please check the errors above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure Docker containers are running: docker-compose up -d"
    Write-Host "2. Check container logs: docker-compose logs <service-name>"
    Write-Host "3. Verify port availability: netstat -an | findstr ""910[0-3]"""
    Write-Host "4. See installation guide: https://github.com/Tapiocapioca/brainery/blob/master/docs/en/installation.md"
    exit 1
}
