#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
# SCRIPT DE VÉRIFICATION DES SERVICES
# Vérifie l'état de tous les services déployés sur le VPS
# ═══════════════════════════════════════════════════════════════════════

VPS_IP="${1:-92.222.243.220}"
SSH_PASS="${2:-}"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}═══ Vérification des services — ${VPS_IP} ═══${NC}"
echo ""

# ─── Test SSH ─────────────────────────────────────────────────────────
echo -e "${BOLD}1. Connectivité SSH${NC}"
if [ -n "$SSH_PASS" ]; then
    if sshpass -p "$SSH_PASS" ssh $SSH_OPTS ubuntu@${VPS_IP} "echo OK" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} SSH accessible"
    else
        echo -e "  ${RED}✗${NC} SSH inaccessible"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Mot de passe SSH non fourni, test par ports uniquement"
fi

# ─── Tests HTTP ───────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}2. Services HTTP${NC}"

check_http() {
    local name=$1
    local url=$2
    local status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
    if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ] || [ "$status" = "304" ]; then
        echo -e "  ${GREEN}✓${NC} $name — HTTP $status"
    elif [ "$status" = "000" ]; then
        echo -e "  ${RED}✗${NC} $name — Non accessible"
    else
        echo -e "  ${YELLOW}⚠${NC} $name — HTTP $status"
    fi
}

check_http "Site web (port 80)"      "http://${VPS_IP}/"
check_http "Twenty CRM (port 3000)"  "http://${VPS_IP}:3000/"
check_http "Fire-Enrich (port 3001)" "http://${VPS_IP}:3001/"
check_http "n8n (port 5678)"         "http://${VPS_IP}:5678/"

# ─── Tests ports TCP ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}3. Ports TCP${NC}"

check_port() {
    local port=$1
    local name=$2
    if timeout 3 bash -c "echo >/dev/tcp/${VPS_IP}/$port" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Port $port ($name) — Ouvert"
    else
        echo -e "  ${RED}✗${NC} Port $port ($name) — Fermé/Filtré"
    fi
}

check_port 22   "SSH"
check_port 80   "HTTP"
check_port 443  "HTTPS"
check_port 3000 "Twenty CRM"
check_port 3001 "Fire-Enrich"
check_port 5678 "n8n"

# ─── Docker status (si SSH disponible) ────────────────────────────────
if [ -n "$SSH_PASS" ]; then
    echo ""
    echo -e "${BOLD}4. Conteneurs Docker${NC}"
    sshpass -p "$SSH_PASS" ssh $SSH_OPTS ubuntu@${VPS_IP} "docker ps --format '  {{.Names}}\t{{.Status}}\t{{.Ports}}'" 2>/dev/null || echo -e "  ${YELLOW}⚠${NC} Impossible de récupérer l'état Docker"
fi

echo ""
echo -e "${BOLD}═══ Vérification terminée ═══${NC}"
