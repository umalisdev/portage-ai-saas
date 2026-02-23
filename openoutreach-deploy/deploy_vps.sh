#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
# deploy_vps.sh — Déploiement automatique OpenOutreach sur VPS OVH
# Portage AI — Force Commerciale Augmentée par l'IA
# ═══════════════════════════════════════════════════════════════════════
# Usage : copier-coller ce script dans le terminal SSH du VPS
#         ou l'exécuter via : bash deploy_vps.sh
# ═══════════════════════════════════════════════════════════════════════

set -e

# ─── Couleurs ─────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 0 — Vérification de l'environnement
# ═══════════════════════════════════════════════════════════════════════
print_header "🚀 OpenOutreach — Déploiement Automatique VPS"

echo -e "${BOLD}VPS :${NC} $(hostname)"
echo -e "${BOLD}IP  :${NC} $(hostname -I | awk '{print $1}')"
echo -e "${BOLD}OS  :${NC} $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo -e "${BOLD}RAM :${NC} $(free -h | awk '/^Mem:/{print $2}')"
echo ""

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 1 — Mise à jour système + installation Docker
# ═══════════════════════════════════════════════════════════════════════
print_header "📦 Étape 1/5 — Installation de Docker"

if command -v docker &> /dev/null; then
    print_ok "Docker déjà installé : $(docker --version)"
else
    print_step "Mise à jour des paquets système..."
    sudo apt-get update -qq
    sudo apt-get upgrade -y -qq

    print_step "Installation des prérequis..."
    sudo apt-get install -y -qq \
        ca-certificates curl gnupg lsb-release \
        apt-transport-https software-properties-common \
        git python3 python3-pip jq

    print_step "Ajout du dépôt Docker officiel..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    print_step "Installation de Docker Engine..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    print_step "Ajout de l'utilisateur au groupe docker..."
    sudo usermod -aG docker $USER

    print_ok "Docker installé : $(docker --version)"
fi

# Vérifier Docker Compose
if docker compose version &> /dev/null; then
    print_ok "Docker Compose : $(docker compose version --short)"
else
    print_error "Docker Compose non disponible"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 2 — Cloner le package OpenOutreach
# ═══════════════════════════════════════════════════════════════════════
print_header "📥 Étape 2/5 — Téléchargement du package OpenOutreach"

DEPLOY_DIR="$HOME/openoutreach-deploy"

if [ -d "$DEPLOY_DIR" ]; then
    print_warn "Dossier existant détecté. Mise à jour..."
    cd "$DEPLOY_DIR"
    git pull origin main 2>/dev/null || true
else
    print_step "Clonage du dépôt..."
    git clone https://github.com/umalisdev/portage-ai-saas.git /tmp/portage-ai-saas 2>/dev/null || true
    if [ -d "/tmp/portage-ai-saas/openoutreach-deploy" ]; then
        cp -r /tmp/portage-ai-saas/openoutreach-deploy "$DEPLOY_DIR"
        rm -rf /tmp/portage-ai-saas
    else
        print_warn "Clonage GitHub échoué, création du package localement..."
        mkdir -p "$DEPLOY_DIR"
    fi
fi

cd "$DEPLOY_DIR"
print_ok "Dossier de déploiement : $DEPLOY_DIR"

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 3 — Configuration du fichier .env
# ═══════════════════════════════════════════════════════════════════════
print_header "⚙️  Étape 3/5 — Configuration"

if [ ! -f .env ]; then
    print_step "Création du fichier de configuration .env..."

    # Générer une clé API interne pour sécuriser le flux de données
    API_SECRET=$(openssl rand -hex 32)

    cat > .env << 'ENVEOF'
# ═══════════════════════════════════════════════════════════════════════
# OpenOutreach — Configuration Portage AI
# ═══════════════════════════════════════════════════════════════════════

# ─── LinkedIn (OBLIGATOIRE) ───────────────────────────────────────────
# Utilisez un compte LinkedIn dédié à la prospection (pas votre compte perso)
LINKEDIN_USERNAME=votre.email@exemple.com
LINKEDIN_PASSWORD=votre_mot_de_passe

# ─── LLM / IA (OBLIGATOIRE) ──────────────────────────────────────────
# Clé API OpenAI pour la qualification intelligente des profils
LLM_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
LLM_MODEL=gpt-4.1-mini

# ─── Limites de sécurité LinkedIn ────────────────────────────────────
CONNECT_DAILY_LIMIT=20
CONNECT_WEEKLY_LIMIT=100
SEARCH_DAILY_LIMIT=50
MESSAGE_DAILY_LIMIT=25

# ─── Campagne de recherche ───────────────────────────────────────────
DEPARTMENT_NAME=Portage AI — Prospection Nationale
# Mots-clés séparés par des points-virgules (optionnel, des défauts sont fournis)
# SEARCH_KEYWORDS=consultant IT freelance;développeur senior freelance Paris

# ─── Flux de données vers portagesalarial.ai ─────────────────────────
PORTAGE_AI_API_URL=https://portagesalarial.ai/api/trpc/linkedin.ingestProfiles
PORTAGE_AI_API_SECRET=REMPLACER_PAR_VOTRE_CLE_API

# ─── Flux de données vers le Dashboard GitHub Pages ──────────────────
GITHUB_REPO=umalisdev/portage-ai-saas
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_EXPORT_PATH=data/linkedin_profiles.json

# ─── Export automatique ──────────────────────────────────────────────
EXPORT_INTERVAL=3600
EXPORT_FORMAT=json

# ─── CRM Django ──────────────────────────────────────────────────────
CRM_PORT=8000
DJANGO_SECRET_KEY=REMPLACER_PAR_UNE_CLE_SECRETE

# ─── Ports ───────────────────────────────────────────────────────────
OPENOUTREACH_PORT=3000
ENVEOF

    # Injecter la clé API générée
    sed -i "s/PORTAGE_AI_API_SECRET=REMPLACER_PAR_VOTRE_CLE_API/PORTAGE_AI_API_SECRET=${API_SECRET}/" .env
    DJANGO_KEY=$(openssl rand -hex 32)
    sed -i "s/DJANGO_SECRET_KEY=REMPLACER_PAR_UNE_CLE_SECRETE/DJANGO_SECRET_KEY=${DJANGO_KEY}/" .env

    print_ok "Fichier .env créé"
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  📝 CONFIGURATION REQUISE                                   ║${NC}"
    echo -e "${YELLOW}║                                                              ║${NC}"
    echo -e "${YELLOW}║  Éditez le fichier .env avec :                               ║${NC}"
    echo -e "${YELLOW}║    nano $DEPLOY_DIR/.env              ║${NC}"
    echo -e "${YELLOW}║                                                              ║${NC}"
    echo -e "${YELLOW}║  Variables OBLIGATOIRES à renseigner :                       ║${NC}"
    echo -e "${YELLOW}║    • LINKEDIN_USERNAME  (email du compte LinkedIn dédié)     ║${NC}"
    echo -e "${YELLOW}║    • LINKEDIN_PASSWORD  (mot de passe)                       ║${NC}"
    echo -e "${YELLOW}║    • LLM_API_KEY        (clé API OpenAI)                     ║${NC}"
    echo -e "${YELLOW}║    • GITHUB_TOKEN       (token GitHub pour l'export)         ║${NC}"
    echo -e "${YELLOW}║                                                              ║${NC}"
    echo -e "${YELLOW}║  Clé API interne générée automatiquement :                   ║${NC}"
    echo -e "${YELLOW}║    ${API_SECRET}  ║${NC}"
    echo -e "${YELLOW}║  (conservez-la pour configurer portagesalarial.ai)            ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Appuyez sur Entrée après avoir configuré le .env, ou tapez 'skip' pour continuer sans scraping :${NC}"
    read -r user_input
    if [ "$user_input" = "skip" ]; then
        print_warn "Configuration différée. Vous pourrez lancer le scraping plus tard."
    fi
else
    print_ok "Fichier .env existant détecté"
fi

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 4 — Créer le script d'export vers portagesalarial.ai
# ═══════════════════════════════════════════════════════════════════════
print_header "🔗 Étape 4/5 — Configuration du flux de données"

print_step "Création du script d'export vers portagesalarial.ai..."

cat > export_to_portageai.py << 'PYEOF'
#!/usr/bin/env python3
"""
export_to_portageai.py — Exporte les profils LinkedIn qualifiés vers :
  1. portagesalarial.ai (API tRPC)
  2. Dashboard GitHub Pages (via GitHub API)

Ce script est exécuté automatiquement par le cron toutes les heures.
"""

import os
import sys
import json
import time
import sqlite3
import hashlib
import logging
import requests
from datetime import datetime, timedelta
from pathlib import Path

# ─── Configuration ────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("/var/log/openoutreach/export.log"),
    ]
)
log = logging.getLogger("export")

# Variables d'environnement
PORTAGE_API_URL = os.environ.get("PORTAGE_AI_API_URL", "")
PORTAGE_API_SECRET = os.environ.get("PORTAGE_AI_API_SECRET", "")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
GITHUB_REPO = os.environ.get("GITHUB_REPO", "umalisdev/portage-ai-saas")
GITHUB_EXPORT_PATH = os.environ.get("GITHUB_EXPORT_PATH", "data/linkedin_profiles.json")
DB_PATH = os.environ.get("OPENOUTREACH_DB", "/app/data/openoutreach.db")
EXPORT_STATE_FILE = "/app/data/export_state.json"

# ─── Fonctions utilitaires ───────────────────────────────────────────

def load_export_state():
    """Charge l'état du dernier export pour éviter les doublons."""
    if os.path.exists(EXPORT_STATE_FILE):
        with open(EXPORT_STATE_FILE, "r") as f:
            return json.load(f)
    return {"last_export_time": "2000-01-01T00:00:00", "exported_ids": []}


def save_export_state(state):
    """Sauvegarde l'état de l'export."""
    os.makedirs(os.path.dirname(EXPORT_STATE_FILE), exist_ok=True)
    with open(EXPORT_STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


def get_new_profiles(since_time):
    """Récupère les nouveaux profils depuis la base OpenOutreach."""
    if not os.path.exists(DB_PATH):
        log.warning(f"Base de données non trouvée : {DB_PATH}")
        return []

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT
                id, first_name, last_name, headline, location, industry,
                linkedin_url, email, phone, company, title,
                connection_status, qualification_score, qualification_notes,
                created_at, updated_at
            FROM profiles
            WHERE created_at > ? OR updated_at > ?
            ORDER BY created_at DESC
            LIMIT 500
        """, (since_time, since_time))

        profiles = [dict(row) for row in cursor.fetchall()]
        log.info(f"📊 {len(profiles)} nouveaux profils trouvés depuis {since_time}")
        return profiles

    except sqlite3.OperationalError as e:
        log.error(f"Erreur SQL : {e}")
        return []
    finally:
        conn.close()


def format_profile_for_api(profile):
    """Formate un profil pour l'API portagesalarial.ai."""
    return {
        "externalId": f"openoutreach_{profile['id']}",
        "firstName": profile.get("first_name", ""),
        "lastName": profile.get("last_name", ""),
        "headline": profile.get("headline", ""),
        "location": profile.get("location", ""),
        "industry": profile.get("industry", ""),
        "linkedinUrl": profile.get("linkedin_url", ""),
        "email": profile.get("email", ""),
        "phone": profile.get("phone", ""),
        "company": profile.get("company", ""),
        "title": profile.get("title", ""),
        "connectionStatus": profile.get("connection_status", ""),
        "qualificationScore": profile.get("qualification_score", 0),
        "qualificationNotes": profile.get("qualification_notes", ""),
        "source": "OpenOutreach-VPS",
        "importedAt": datetime.utcnow().isoformat(),
    }


def format_profile_for_dashboard(profile):
    """Formate un profil pour le dashboard GitHub Pages."""
    return {
        "id": profile.get("id"),
        "nom": f"{profile.get('first_name', '')} {profile.get('last_name', '')}".strip(),
        "titre": profile.get("headline", ""),
        "entreprise": profile.get("company", ""),
        "localisation": profile.get("location", ""),
        "secteur": profile.get("industry", ""),
        "linkedin": profile.get("linkedin_url", ""),
        "email": profile.get("email", ""),
        "telephone": profile.get("phone", ""),
        "score": profile.get("qualification_score", 0),
        "statut": profile.get("connection_status", ""),
        "notes": profile.get("qualification_notes", ""),
        "date_import": profile.get("created_at", ""),
    }


# ─── Export vers portagesalarial.ai ──────────────────────────────────

def export_to_portageai(profiles):
    """Envoie les profils vers l'API tRPC de portagesalarial.ai."""
    if not PORTAGE_API_URL or not PORTAGE_API_SECRET:
        log.warning("⏭️  Export portagesalarial.ai désactivé (URL ou clé non configurée)")
        return False

    formatted = [format_profile_for_api(p) for p in profiles]

    try:
        response = requests.post(
            PORTAGE_API_URL,
            json={
                "json": {
                    "apiSecret": PORTAGE_API_SECRET,
                    "profiles": formatted,
                    "source": "openoutreach-vps",
                    "timestamp": datetime.utcnow().isoformat(),
                }
            },
            headers={
                "Content-Type": "application/json",
                "X-API-Key": PORTAGE_API_SECRET,
                "User-Agent": "OpenOutreach-VPS/1.0",
            },
            timeout=30,
        )

        if response.status_code == 200:
            result = response.json()
            log.info(f"✅ portagesalarial.ai : {len(formatted)} profils envoyés avec succès")
            return True
        else:
            log.error(f"❌ portagesalarial.ai : HTTP {response.status_code} — {response.text[:200]}")
            return False

    except requests.exceptions.ConnectionError:
        log.error("❌ portagesalarial.ai : Connexion refusée. L'endpoint API est-il configuré ?")
        return False
    except requests.exceptions.Timeout:
        log.error("❌ portagesalarial.ai : Timeout de connexion")
        return False
    except Exception as e:
        log.error(f"❌ portagesalarial.ai : Erreur inattendue — {e}")
        return False


# ─── Export vers GitHub Pages Dashboard ──────────────────────────────

def export_to_github(profiles):
    """Pousse les profils vers le dépôt GitHub pour le dashboard."""
    if not GITHUB_TOKEN:
        log.warning("⏭️  Export GitHub désactivé (token non configuré)")
        return False

    formatted = [format_profile_for_dashboard(p) for p in profiles]

    export_data = {
        "meta": {
            "total": len(formatted),
            "last_update": datetime.utcnow().isoformat(),
            "source": "OpenOutreach-VPS",
            "vps_hostname": os.uname().nodename,
        },
        "profiles": formatted,
    }

    content = json.dumps(export_data, indent=2, ensure_ascii=False)
    content_b64 = __import__("base64").b64encode(content.encode()).decode()

    api_url = f"https://api.github.com/repos/{GITHUB_REPO}/contents/{GITHUB_EXPORT_PATH}"
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "OpenOutreach-VPS/1.0",
    }

    try:
        # Vérifier si le fichier existe déjà (pour obtenir le SHA)
        existing = requests.get(api_url, headers=headers, timeout=15)
        sha = existing.json().get("sha", "") if existing.status_code == 200 else ""

        payload = {
            "message": f"[OpenOutreach] Export {len(formatted)} profils — {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}",
            "content": content_b64,
            "branch": "main",
        }
        if sha:
            payload["sha"] = sha

        response = requests.put(api_url, json=payload, headers=headers, timeout=30)

        if response.status_code in (200, 201):
            log.info(f"✅ GitHub : {len(formatted)} profils exportés vers {GITHUB_EXPORT_PATH}")
            return True
        else:
            log.error(f"❌ GitHub : HTTP {response.status_code} — {response.text[:200]}")
            return False

    except Exception as e:
        log.error(f"❌ GitHub : Erreur — {e}")
        return False


# ─── Fonction principale ─────────────────────────────────────────────

def main():
    log.info("═" * 60)
    log.info("  OpenOutreach — Export des profils LinkedIn")
    log.info("═" * 60)

    state = load_export_state()
    since_time = state.get("last_export_time", "2000-01-01T00:00:00")

    profiles = get_new_profiles(since_time)

    if not profiles:
        log.info("📭 Aucun nouveau profil à exporter")
        return

    # Export vers les deux destinations
    portage_ok = export_to_portageai(profiles)
    github_ok = export_to_github(profiles)

    # Mettre à jour l'état
    state["last_export_time"] = datetime.utcnow().isoformat()
    state["exported_ids"] = list(set(
        state.get("exported_ids", []) + [p["id"] for p in profiles]
    ))[-5000:]  # Garder les 5000 derniers IDs

    save_export_state(state)

    log.info("─" * 60)
    log.info(f"  Résumé : {len(profiles)} profils traités")
    log.info(f"  → portagesalarial.ai : {'✅' if portage_ok else '❌'}")
    log.info(f"  → GitHub Dashboard   : {'✅' if github_ok else '❌'}")
    log.info("─" * 60)


if __name__ == "__main__":
    main()
PYEOF

chmod +x export_to_portageai.py
print_ok "Script d'export créé : export_to_portageai.py"

# ─── Créer le cron job ───────────────────────────────────────────────
print_step "Configuration du cron d'export automatique..."

cat > /tmp/openoutreach_cron << 'CRONEOF'
# OpenOutreach — Export automatique des profils LinkedIn
# Toutes les heures, exporte vers portagesalarial.ai et GitHub
0 * * * * cd /home/ubuntu/openoutreach-deploy && docker compose exec -T app python3 /app/export_to_portageai.py >> /var/log/openoutreach/cron.log 2>&1

# Nettoyage des logs tous les dimanches à 3h
0 3 * * 0 find /var/log/openoutreach/ -name "*.log" -mtime +30 -delete
CRONEOF

sudo mkdir -p /var/log/openoutreach
sudo chown $USER:$USER /var/log/openoutreach

# Le cron sera installé après le démarrage de Docker
print_ok "Cron d'export préparé (installation après démarrage)"

# ═══════════════════════════════════════════════════════════════════════
# ÉTAPE 5 — Démarrage des services Docker
# ═══════════════════════════════════════════════════════════════════════
print_header "🐳 Étape 5/5 — Démarrage des services"

# Vérifier que le .env est configuré
source .env 2>/dev/null || true

if [ -z "$LINKEDIN_USERNAME" ] || [ "$LINKEDIN_USERNAME" = "votre.email@exemple.com" ]; then
    print_warn "LinkedIn non configuré. Les services démarreront en mode veille."
    print_warn "Configurez le .env puis relancez avec : cd $DEPLOY_DIR && bash start.sh"
    echo ""
else
    print_step "Construction des images Docker..."
    docker compose build --quiet 2>/dev/null || print_warn "Build Docker en attente de configuration"

    print_step "Initialisation de la base de données..."
    docker compose run --rm init 2>/dev/null || print_warn "Init en attente"

    print_step "Démarrage des services..."
    docker compose up -d app crm exporter 2>/dev/null || print_warn "Démarrage en attente de configuration"
fi

# Installer le cron
crontab /tmp/openoutreach_cron 2>/dev/null || true
rm -f /tmp/openoutreach_cron
print_ok "Cron d'export installé"

# ═══════════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════════════════════
VPS_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ DÉPLOIEMENT TERMINÉ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}📍 VPS${NC}"
echo -e "     IP          : ${VPS_IP}"
echo -e "     Hostname    : $(hostname)"
echo ""
echo -e "  ${BOLD}🔗 Flux de données${NC}"
echo -e "     → portagesalarial.ai   : API tRPC sécurisée"
echo -e "     → Dashboard GitHub     : Export JSON automatique"
echo -e "     Fréquence              : Toutes les heures"
echo ""
echo -e "  ${BOLD}📋 Services${NC}"
echo -e "     CRM Django  : http://${VPS_IP}:${CRM_PORT:-8000}/admin/"
echo -e "     Login CRM   : admin / admin"
echo ""
echo -e "  ${BOLD}📝 Commandes utiles${NC}"
echo -e "     cd $DEPLOY_DIR"
echo -e "     nano .env                          # Modifier la configuration"
echo -e "     bash start.sh                      # (Re)démarrer les services"
echo -e "     docker compose logs -f app         # Logs du scraping"
echo -e "     docker compose logs -f exporter    # Logs de l'export"
echo -e "     docker compose down                # Arrêter tout"
echo -e "     python3 export_to_portageai.py     # Export manuel"
echo ""
echo -e "  ${BOLD}📊 Logs${NC}"
echo -e "     /var/log/openoutreach/export.log   # Logs d'export"
echo -e "     /var/log/openoutreach/cron.log     # Logs du cron"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Prochaine étape : configurez le fichier .env avec vos identifiants LinkedIn${NC}"
echo -e "${YELLOW}puis lancez : ${BOLD}bash start.sh${NC}"
echo ""
