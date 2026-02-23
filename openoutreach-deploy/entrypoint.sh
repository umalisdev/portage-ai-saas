#!/bin/bash
# ─────────────────────────────────────────────────────────────────────
# entrypoint.sh — OpenOutreach Docker Entrypoint
# Gère les différents modes de démarrage
# ─────────────────────────────────────────────────────────────────────
set -e

# Couleurs pour les logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }

# Vérifier les variables d'environnement requises
check_env() {
    local missing=0
    if [ -z "$LINKEDIN_USERNAME" ]; then
        error "LINKEDIN_USERNAME non défini dans .env"
        missing=1
    fi
    if [ -z "$LINKEDIN_PASSWORD" ]; then
        error "LINKEDIN_PASSWORD non défini dans .env"
        missing=1
    fi
    if [ -z "$LLM_API_KEY" ]; then
        error "LLM_API_KEY non défini dans .env"
        missing=1
    fi
    if [ $missing -eq 1 ]; then
        error "Variables d'environnement manquantes. Vérifiez votre fichier .env"
        exit 1
    fi
    success "Variables d'environnement OK"
}

# Accepter la notice légale
accept_legal() {
    mkdir -p /app/assets/cookies
    touch /app/assets/cookies/.legal_notice_accepted
    success "Notice légale acceptée"
}

# ─── MODE: init ───────────────────────────────────────────────────────
# Initialise la base de données, crée la campagne et le profil LinkedIn
mode_init() {
    log "🔧 Mode: INITIALISATION"
    check_env
    accept_legal

    log "Migration de la base de données..."
    python manage.py migrate --no-input
    success "Migrations OK"

    log "Configuration du CRM..."
    python manage.py setup_crm 2>/dev/null || true
    success "CRM configuré"

    log "Initialisation Portage AI (campagne, profil, mots-clés)..."
    python init_portage_ai.py
    success "Configuration Portage AI terminée"

    log "Création du superuser admin..."
    python -c "
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'linkedin.django_settings')
import django
django.setup()
from django.contrib.auth.models import User
if not User.objects.filter(is_superuser=True).exists():
    User.objects.create_superuser('admin', 'admin@portage-ai.fr', 'admin')
    print('Superuser admin créé (login: admin / password: admin)')
else:
    print('Superuser déjà existant')
" 2>/dev/null || true

    success "INITIALISATION TERMINÉE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✅ OpenOutreach est prêt !"
    echo "  📋 CRM: http://localhost:8000/admin/ (admin/admin)"
    echo "  🔑 LinkedIn: $LINKEDIN_USERNAME"
    echo "  🤖 LLM: $(echo $LLM_API_KEY | head -c 8)..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ─── MODE: daemon ─────────────────────────────────────────────────────
# Lance le daemon de scraping LinkedIn avec xvfb
mode_daemon() {
    log "🚀 Mode: DAEMON SCRAPING LINKEDIN"
    check_env
    accept_legal

    log "Démarrage du daemon avec xvfb (écran virtuel 1920x1080)..."
    log "Mots-clés de recherche configurés pour Portage AI"
    log "Limites: 20 connexions/jour, 100/semaine"
    echo ""

    exec xvfb-run \
        --auto-servernum \
        --server-args="-screen 0 1920x1080x24 -ac" \
        python manage.py
}

# ─── MODE: crm ────────────────────────────────────────────────────────
# Lance le serveur web CRM Django
mode_crm() {
    log "🌐 Mode: SERVEUR CRM DJANGO"

    log "Démarrage du serveur web sur le port 8000..."
    exec python manage.py runserver 0.0.0.0:8000
}

# ─── MODE: exporter ───────────────────────────────────────────────────
# Export automatique des profils vers le dashboard
mode_exporter() {
    log "📊 Mode: EXPORT AUTOMATIQUE"

    INTERVAL=${EXPORT_INTERVAL:-3600}
    DASHBOARD=${DASHBOARD_PATH:-/dashboard/dashboard.html}

    log "Intervalle d'export: ${INTERVAL}s ($(( INTERVAL / 60 )) min)"
    log "Fichier dashboard: $DASHBOARD"
    echo ""

    while true; do
        log "Export des profils vers le dashboard..."

        if [ -f "$DASHBOARD" ]; then
            python export_to_dashboard.py --inject "$DASHBOARD" 2>&1
            success "Export terminé"
        else
            warn "Fichier dashboard non trouvé: $DASHBOARD"
            log "Export en mode JSON..."
            python export_to_dashboard.py --json -o /dashboard/profiles.json 2>&1
            success "Export JSON terminé → /dashboard/profiles.json"
        fi

        log "Prochain export dans $(( INTERVAL / 60 )) minutes..."
        sleep "$INTERVAL"
    done
}

# ─── MODE: export-once ────────────────────────────────────────────────
# Export unique (pour usage manuel)
mode_export_once() {
    log "📊 Mode: EXPORT UNIQUE"

    DASHBOARD=${DASHBOARD_PATH:-/dashboard/dashboard.html}

    if [ -f "$DASHBOARD" ]; then
        python export_to_dashboard.py --inject "$DASHBOARD" 2>&1
    else
        python export_to_dashboard.py --json -o /dashboard/profiles.json 2>&1
    fi

    success "Export terminé"
}

# ─── MODE: shell ──────────────────────────────────────────────────────
# Ouvre un shell interactif
mode_shell() {
    log "🐚 Mode: SHELL INTERACTIF"
    exec /bin/bash
}

# ─── Dispatch ─────────────────────────────────────────────────────────
case "${1:-daemon}" in
    init)
        mode_init
        ;;
    daemon)
        mode_daemon
        ;;
    crm)
        mode_crm
        ;;
    exporter)
        mode_exporter
        ;;
    export-once)
        mode_export_once
        ;;
    shell)
        mode_shell
        ;;
    *)
        echo "Usage: entrypoint.sh {init|daemon|crm|exporter|export-once|shell}"
        echo ""
        echo "Modes disponibles:"
        echo "  init        - Initialise la base de données et la configuration"
        echo "  daemon      - Lance le daemon de scraping LinkedIn"
        echo "  crm         - Lance le serveur web CRM (port 8000)"
        echo "  exporter    - Export automatique vers le dashboard (cron)"
        echo "  export-once - Export unique vers le dashboard"
        echo "  shell       - Ouvre un shell interactif"
        exit 1
        ;;
esac
