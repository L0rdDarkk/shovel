#!/bin/bash
# Shovel Version 1.0
# Team Albania CTF EDTION by Juled Mardodaj | Tedi Vyshka | Jetmir Rajta 


set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

clear
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════╗
║   Shovel Enhanced Setup               ║
║   Team Albania - Enchaced             ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

# ============================================================================
# STEP 1: Check Requirements
# ============================================================================
log_info "Checking requirements..."
echo ""

MISSING=0

# Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    log_success "Docker $DOCKER_VERSION"
else
    log_error "Docker NOT installed"
    echo "         Install: https://docs.docker.com/get-docker/"
    MISSING=1
fi

# Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f4 | cut -d',' -f1)
    log_success "docker-compose $COMPOSE_VERSION"
elif docker compose version &> /dev/null 2>&1; then
    log_success "Docker Compose plugin"
else
    log_error "Docker Compose NOT installed"
    MISSING=1
fi

# Docker daemon
if docker info &> /dev/null 2>&1; then
    log_success "Docker daemon running"
else
    log_error "Docker daemon NOT running"
    echo "         Start Docker and run setup again"
    MISSING=1
fi

# Check disk space
AVAILABLE_SPACE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -gt 10 ]; then
    log_success "Disk space: ${AVAILABLE_SPACE}GB available"
else
    log_warning "Low disk space: ${AVAILABLE_SPACE}GB (recommend 10GB+)"
fi

if [ $MISSING -eq 1 ]; then
    echo ""
    log_error "Missing requirements! Install them and run setup again"
    exit 1
fi

echo ""
log_success "All requirements OK!"

# ============================================================================
# STEP 2: Create Directories
# ============================================================================
echo ""
log_info "Creating directories..."

mkdir -p suricata/rules
mkdir -p suricata/logs
mkdir -p input_pcaps
mkdir -p data
mkdir -p backups

log_success "Directories created"

# ============================================================================
# STEP 3: Create Configuration Files
# ============================================================================
echo ""
log_info "Creating configuration files..."

# Check if .env.example exists
if [ ! -f .env.example ]; then
    log_error ".env.example not found!"
    echo "         This file should be in the repository"
    exit 1
fi

# Copy .env.example to .env
if [ -f .env ]; then
    log_warning ".env already exists"
    read -p "         Overwrite? (y/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        log_info "Keeping existing .env"
    else
        cp .env.example .env
        log_success ".env created from .env.example"
    fi
else
    cp .env.example .env
    log_success ".env created from .env.example"
fi

# Create default Suricata rules if not exists
if [ ! -f suricata/rules/suricata.rules ]; then
    cat > suricata/rules/suricata.rules << 'EOF'
# Shovel Rules - Team Albania
# Update with your flag format!

# ═══════════════════════════════════════
# FLAG DETECTION - UPDATE THIS!
# ═══════════════════════════════════════
alert tcp any any -> any any (msg:"FLAG DETECTED"; content:"ECSC{"; nocase; sid:1000001; rev:1;)
alert udp any any -> any any (msg:"FLAG DETECTED"; content:"ECSC{"; nocase; sid:1000002; rev:1;)

# ═══════════════════════════════════════
# CUSTOM RULES
# ═══════════════════════════════════════
# Add your custom detection rules below:

EOF
    log_success "Default suricata rules created"
else
    log_info "suricata rules already exist (keeping them)"
fi

# ============================================================================
# STEP 4: Detect Network Interfaces (for reference)
# ============================================================================
echo ""
log_info "Available network interfaces:"
echo ""

if command -v ip &> /dev/null; then
    ip -br link | grep -v '^lo' | awk '{print "  - " $1}'
else
    ifconfig -a | grep '^[a-z]' | awk '{gsub(/:/, "", $1); print "  - " $1}'
fi

# ============================================================================
# STEP 5: Summary
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Setup Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " What was created:"
echo "   ✓ .env (from .env.example)"
echo "   ✓ Directory structure"
echo "   ✓ Default Suricata rules"
echo ""
echo " Next Steps:"
echo ""
echo "1️⃣  ${YELLOW}Edit configuration:${NC}"
echo "   nano .env"
echo ""
echo "   Required changes:"
echo "   • CAPTURE_MODE (A/B/C)"
echo "   • CAPTURE_INTERFACE (if Mode B)"
echo "   • HOME_NET (your CTF network)"
echo ""
echo "2️⃣  ${YELLOW}Update flag format:${NC}"
echo "   nano suricata/rules/suricata.rules"
echo ""
echo "   Change 'ECSC{' to your flag format"
echo ""
echo "3️⃣  ${YELLOW}Build and start:${NC}"
echo "   docker-compose up -d --build"
echo ""
echo "   (Mode B needs: sudo docker-compose up -d --build)"
echo ""
echo "4️⃣  ${YELLOW}Check logs:${NC}"
echo "   docker-compose logs -f"
echo ""
echo "5️⃣  ${YELLOW}Access dashboard:${NC}"
echo "   http://localhost:8000"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " Useful commands:"
echo "   docker-compose ps              - Check status"
echo "   docker-compose logs -f         - View logs"
echo "   docker-compose down            - Stop services"
echo "   docker-compose restart webapp  - Restart only webapp"
echo ""
echo -e "${BLUE}Good luck Team Albania! 🇦🇱${NC}"
echo ""