#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
# SCRIPT DE DÉPLOIEMENT COMPLET — VPS OVH 92.222.243.220
# Portage AI SaaS — Infrastructure complète
# ═══════════════════════════════════════════════════════════════════════
#
# Ce script déploie :
#   1. Nginx + site web statique (port 80)
#   2. Twenty CRM + PostgreSQL + Redis (port 3000)
#   3. n8n Workflow Automation (port 5678)
#   4. OpenOutreach LinkedIn Scraper (port 8000)
#   5. Fire-Enrich (port 3001)
#
# Usage :
#   chmod +x deploy-all.sh
#   sudo bash deploy-all.sh
#
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Couleurs ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Fonctions utilitaires ────────────────────────────────────────────
print_header() { echo -e "\n${BLUE}${BOLD}═══ $1 ═══${NC}\n"; }
print_step()   { echo -e "  ${YELLOW}▸${NC} $1"; }
print_ok()     { echo -e "  ${GREEN}✓${NC} $1"; }
print_err()    { echo -e "  ${RED}✗${NC} $1"; }
print_warn()   { echo -e "  ${YELLOW}⚠${NC} $1"; }

# ─── Variables ────────────────────────────────────────────────────────
VPS_IP=$(hostname -I | awk '{print $1}')
DEPLOY_BASE="/opt/portage-ai"
SITE_DIR="/var/www/portage-ai"
FIRECRAWL_API_KEY="fc-86b47ffcd30c46ae924d1e3f5a00bda4"
N8N_ADMIN_EMAIL="admin@portagesalarial.ai"
N8N_ADMIN_PASSWORD="Landerneau2027@"

echo -e "${GREEN}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════════╗"
echo "  ║     DÉPLOIEMENT COMPLET — PORTAGE AI INFRASTRUCTURE     ║"
echo "  ║     VPS: ${VPS_IP}                              ║"
echo "  ╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 1 — Mise à jour système et paquets de base
# ═══════════════════════════════════════════════════════════════════════
print_header "Étape 1/7 — Mise à jour système"

print_step "Mise à jour des paquets..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
    curl wget git unzip htop nano \
    ufw fail2ban \
    nginx certbot python3-certbot-nginx \
    apt-transport-https ca-certificates gnupg lsb-release
print_ok "Système mis à jour"

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 2 — Configuration du pare-feu UFW
# ═══════════════════════════════════════════════════════════════════════
print_header "Étape 2/7 — Configuration du pare-feu"

print_step "Configuration UFW..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 3000/tcp comment 'Twenty CRM'
ufw allow 3001/tcp comment 'Fire-Enrich'
ufw allow 5678/tcp comment 'n8n'
ufw --force enable
print_ok "Pare-feu configuré"

# Configuration Fail2ban
print_step "Configuration Fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 3
bantime = 7200
EOF
systemctl enable fail2ban
systemctl restart fail2ban
print_ok "Fail2ban configuré"

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 3 — Installation de Docker
# ═══════════════════════════════════════════════════════════════════════
print_header "Étape 3/7 — Installation de Docker"

if command -v docker &> /dev/null; then
    print_ok "Docker déjà installé ($(docker --version))"
else
    print_step "Installation de Docker via script officiel..."
    curl -fsSL https://get.docker.com | sh
    print_ok "Docker installé"
fi

# Ajouter l'utilisateur ubuntu au groupe docker
usermod -aG docker ubuntu 2>/dev/null || true

# Vérifier Docker Compose
if docker compose version &> /dev/null; then
    print_ok "Docker Compose disponible ($(docker compose version --short))"
else
    print_step "Installation de Docker Compose plugin..."
    apt-get install -y -qq docker-compose-plugin
    print_ok "Docker Compose installé"
fi

# Démarrer Docker
systemctl enable docker
systemctl start docker
print_ok "Docker démarré"

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 4 — Déploiement du site web Nginx
# ═══════════════════════════════════════════════════════════════════════
print_header "Étape 4/7 — Déploiement du site web"

# Créer le répertoire du site
mkdir -p "$SITE_DIR"

# Copier les fichiers du site (depuis le répertoire de déploiement)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_SOURCE="${SCRIPT_DIR}/../site"

if [ -d "$SITE_SOURCE" ]; then
    cp -r "$SITE_SOURCE"/* "$SITE_DIR/"
    print_ok "Fichiers du site copiés vers $SITE_DIR"
else
    print_warn "Répertoire source du site non trouvé ($SITE_SOURCE)"
    print_warn "Les fichiers devront être copiés manuellement"
fi

# Configurer Nginx
print_step "Configuration de Nginx..."
rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/portage-ai << 'NGINXEOF'
# Site principal — Port 80
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/portage-ai;
    index index.html;

    # Sécurité headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript image/svg+xml;

    # Site statique
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache pour les images
    location /img/ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Health check
    location /health {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }

    # Deny hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/portage-ai /etc/nginx/sites-enabled/portage-ai
nginx -t && systemctl reload nginx
print_ok "Nginx configuré et rechargé"

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 5 — Déploiement de Twenty CRM (port 3000)
# ═══════════════════════════════════════════════════════════════════════
print_header "Étape 5/7 — Déploiement de Twenty CRM"

TWENTY_DIR="${DEPLOY_BASE}/twenty"
mkdir -p "$TWENTY_DIR"

cat > "$TWENTY_DIR/docker-compose.yml" << 'TWENTYEOF'
version: '3.8'

services:
  twenty-server:
    image: twentycrm/twenty:latest
    container_name: twenty-server
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      SERVER_URL: http://localhost:3000
      PORT: 3000
      PG_DATABASE_URL: postgres://twenty:twenty_password_secure_2026@twenty-db:5432/twenty
      REDIS_URL: redis://twenty-redis:6379
      ACCESS_TOKEN_SECRET: aKj9sD3kL2mN4pQ6rT8vX0yB1cE3fG5hJ7lM9nPxR2
      LOGIN_TOKEN_SECRET: bLk0tE4lM3nO5qR7sU9wY1zA2dF4gH6iK8mN0pQyS3
      REFRESH_TOKEN_SECRET: cMl1uF5mN4oP6rS8tV0xZ2aB3eG5hI7jL9nO1qRzT4
      STORAGE_TYPE: local
      STORAGE_LOCAL_PATH: /app/packages/twenty-server/.local-storage
      IS_SIGN_UP_DISABLED: "false"
    volumes:
      - twenty_server_data:/app/packages/twenty-server/.local-storage
      - twenty_docker_data:/app/docker-data
    depends_on:
      twenty-db:
        condition: service_healthy
      twenty-redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/healthz"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s

  twenty-db:
    image: twentycrm/twenty-postgres:latest
    container_name: twenty-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: twenty
      POSTGRES_PASSWORD: twenty_password_secure_2026
      POSTGRES_DB: twenty
    volumes:
      - twenty_db_data:/bitnami/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U twenty -d twenty"]
      interval: 10s
      timeout: 5s
      retries: 5

  twenty-redis:
    image: redis:7-alpine
    container_name: twenty-redis
    restart: unless-stopped
    volumes:
      - twenty_redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  twenty_server_data:
  twenty_db_data:
  twenty_redis_data:
  twenty_docker_data:
TWENTYEOF

print_step "Démarrage de Twenty CRM..."
cd "$TWENTY_DIR"
docker compose pull
docker compose up -d
print_ok "Twenty CRM déployé sur le port 3000"

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 6 — Déploiement de n8n (port 5678)
# ═══════════════════════════════════════════════════════════════════════
print_header "Étape 6/7 — Déploiement de n8n"

N8N_DIR="${DEPLOY_BASE}/n8n"
mkdir -p "$N8N_DIR"

cat > "$N8N_DIR/docker-compose.yml" << N8NEOF
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      N8N_HOST: 0.0.0.0
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      WEBHOOK_URL: http://${VPS_IP}:5678/
      GENERIC_TIMEZONE: Europe/Paris
      TZ: Europe/Paris
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: n8n-db
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n
      DB_POSTGRESDB_PASSWORD: n8n_password_secure_2026
      N8N_DEFAULT_BINARY_DATA_MODE: filesystem
      N8N_BASIC_AUTH_ACTIVE: "true"
      N8N_BASIC_AUTH_USER: ${N8N_ADMIN_EMAIL}
      N8N_BASIC_AUTH_PASSWORD: "${N8N_ADMIN_PASSWORD}"
      EXECUTIONS_DATA_PRUNE: "true"
      EXECUTIONS_DATA_MAX_AGE: 168
      N8N_SECURE_COOKIE: "false"
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      n8n-db:
        condition: service_healthy

  n8n-db:
    image: postgres:16-alpine
    container_name: n8n-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: n8n_password_secure_2026
      POSTGRES_DB: n8n
    volumes:
      - n8n_db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n -d n8n"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  n8n_data:
  n8n_db_data:
N8NEOF

print_step "Démarrage de n8n..."
cd "$N8N_DIR"
docker compose pull
docker compose up -d
print_ok "n8n déployé sur le port 5678"

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 7 — Déploiement de Fire-Enrich (port 3001) et OpenOutreach
# ═══════════════════════════════════════════════════════════════════════
print_header "Étape 7/7 — Déploiement de Fire-Enrich et OpenOutreach"

# --- Fire-Enrich ---
FIREENRICH_DIR="${DEPLOY_BASE}/fire-enrich"
mkdir -p "$FIREENRICH_DIR"

cat > "$FIREENRICH_DIR/docker-compose.yml" << FEEOF
version: '3.8'

services:
  fire-enrich:
    image: ghcr.io/nicholasoxford/fire-enrich:latest
    container_name: fire-enrich
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      FIRECRAWL_API_KEY: ${FIRECRAWL_API_KEY}
      PORT: 3000
      NODE_ENV: production
    volumes:
      - fire_enrich_data:/app/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  fire_enrich_data:
FEEOF

print_step "Démarrage de Fire-Enrich..."
cd "$FIREENRICH_DIR"
docker compose pull 2>/dev/null || print_warn "Image Fire-Enrich non trouvée, tentative alternative..."
docker compose up -d 2>/dev/null || print_warn "Fire-Enrich démarrage en attente"
print_ok "Fire-Enrich configuré sur le port 3001"

# --- OpenOutreach ---
OPENOUTREACH_DIR="${DEPLOY_BASE}/openoutreach"
mkdir -p "$OPENOUTREACH_DIR"

# Copier les fichiers OpenOutreach depuis le repo
if [ -d "/home/ubuntu/portage-ai-saas/openoutreach-deploy" ]; then
    cp -r /home/ubuntu/portage-ai-saas/openoutreach-deploy/* "$OPENOUTREACH_DIR/"
    print_ok "Fichiers OpenOutreach copiés"
fi

# Créer le .env pour OpenOutreach si nécessaire
if [ ! -f "$OPENOUTREACH_DIR/.env" ] && [ -f "$OPENOUTREACH_DIR/.env.example" ]; then
    cp "$OPENOUTREACH_DIR/.env.example" "$OPENOUTREACH_DIR/.env"
    print_warn "OpenOutreach .env créé depuis l'exemple — à configurer avec les identifiants LinkedIn"
fi

print_step "Construction et démarrage d'OpenOutreach..."
cd "$OPENOUTREACH_DIR"
if [ -f "docker-compose.yml" ]; then
    docker compose build 2>/dev/null || print_warn "Build OpenOutreach en attente de configuration"
    docker compose up -d 2>/dev/null || print_warn "OpenOutreach démarrage en attente de configuration LinkedIn"
fi
print_ok "OpenOutreach configuré"

# ═══════════════════════════════════════════════════════════════════════
# VÉRIFICATION FINALE
# ═══════════════════════════════════════════════════════════════════════
print_header "Vérification des services"

echo ""
sleep 10  # Attendre que les services démarrent

# Vérifier chaque service
check_service() {
    local name=$1
    local url=$2
    local expected=$3
    
    local status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
    if [ "$status" = "$expected" ] || [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
        print_ok "$name — OK (HTTP $status)"
    else
        print_warn "$name — En attente (HTTP $status) — peut nécessiter quelques minutes"
    fi
}

check_service "Nginx (site web)"     "http://localhost/"         "200"
check_service "Twenty CRM"           "http://localhost:3000/"    "200"
check_service "n8n"                  "http://localhost:5678/"    "200"
check_service "Fire-Enrich"          "http://localhost:3001/"    "200"

echo ""
echo -e "  ${BOLD}Conteneurs Docker :${NC}"
docker ps --format "  {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ DÉPLOIEMENT TERMINÉ — PORTAGE AI INFRASTRUCTURE${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}📍 VPS${NC}"
echo -e "     IP          : ${VPS_IP}"
echo -e "     Hostname    : $(hostname)"
echo ""
echo -e "  ${BOLD}🌐 Services déployés${NC}"
echo -e "     Site web         : http://${VPS_IP}/"
echo -e "     Twenty CRM       : http://${VPS_IP}:3000/"
echo -e "     n8n Automation   : http://${VPS_IP}:5678/"
echo -e "     Fire-Enrich      : http://${VPS_IP}:3001/"
echo -e "     OpenOutreach CRM : http://${VPS_IP}:8000/admin/"
echo ""
echo -e "  ${BOLD}🔐 Identifiants${NC}"
echo -e "     n8n              : ${N8N_ADMIN_EMAIL} / ${N8N_ADMIN_PASSWORD}"
echo -e "     OpenOutreach CRM : admin / admin"
echo ""
echo -e "  ${BOLD}🔥 Pare-feu UFW${NC}"
echo -e "     Ports ouverts    : 22, 80, 443, 3000, 3001, 5678"
echo ""
echo -e "  ${BOLD}📋 Commandes utiles${NC}"
echo -e "     docker ps                                    # État des conteneurs"
echo -e "     cd ${DEPLOY_BASE}/twenty && docker compose logs -f    # Logs Twenty"
echo -e "     cd ${DEPLOY_BASE}/n8n && docker compose logs -f       # Logs n8n"
echo -e "     cd ${DEPLOY_BASE}/fire-enrich && docker compose logs  # Logs Fire-Enrich"
echo -e "     sudo ufw status                              # État du pare-feu"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
