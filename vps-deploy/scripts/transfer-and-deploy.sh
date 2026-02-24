#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
# SCRIPT DE TRANSFERT ET DÉPLOIEMENT DISTANT
# Transfère les fichiers depuis le sandbox Manus vers le VPS OVH
# puis lance le déploiement complet
# ═══════════════════════════════════════════════════════════════════════
#
# Usage :
#   bash transfer-and-deploy.sh <mot_de_passe_ssh>
#
# Exemple :
#   bash transfer-and-deploy.sh 'Landerneau2027@'
#
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

VPS_IP="92.222.243.220"
VPS_USER="ubuntu"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=15"

# Mot de passe SSH (argument ou variable d'environnement)
SSH_PASS="${1:-${VPS_SSH_PASSWORD:-}}"

if [ -z "$SSH_PASS" ]; then
    echo "Usage: $0 <mot_de_passe_ssh>"
    echo "  ou définir VPS_SSH_PASSWORD dans l'environnement"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "  Transfert vers VPS ${VPS_IP}"
echo "═══════════════════════════════════════════════════════════"

# ─── Test de connexion SSH ────────────────────────────────────────────
echo ""
echo "▸ Test de connexion SSH..."
if ! sshpass -p "$SSH_PASS" ssh $SSH_OPTS ${VPS_USER}@${VPS_IP} "echo 'SSH OK'" 2>/dev/null; then
    echo "✗ Connexion SSH impossible."
    echo "  Vérifiez :"
    echo "  - Le mot de passe (OVH peut l'avoir changé après réinstallation)"
    echo "  - L'état du VPS dans l'espace client OVH"
    echo "  - Que le VPS n'est pas bloqué (attaque DDoS précédente)"
    exit 1
fi
echo "✓ Connexion SSH établie"

# ─── Créer les répertoires sur le VPS ─────────────────────────────────
echo ""
echo "▸ Création des répertoires sur le VPS..."
sshpass -p "$SSH_PASS" ssh $SSH_OPTS ${VPS_USER}@${VPS_IP} << 'REMOTECMD'
sudo mkdir -p /var/www/portage-ai/img
sudo mkdir -p /opt/portage-ai/{twenty,n8n,fire-enrich,openoutreach,scripts}
sudo chown -R ubuntu:ubuntu /var/www/portage-ai /opt/portage-ai
REMOTECMD
echo "✓ Répertoires créés"

# ─── Transférer les fichiers du site web ──────────────────────────────
echo ""
echo "▸ Transfert des fichiers du site web..."
SITE_DIR="/home/ubuntu/portage-ai-saas"
if [ -d "$SITE_DIR" ]; then
    # Fichiers HTML
    for f in index.html dashboard.html agents.html tendances-kpis.html presentation-agents.html recherche-linkedin.html etude-architecture.html implementation-suivi.html; do
        if [ -f "$SITE_DIR/$f" ]; then
            sshpass -p "$SSH_PASS" scp $SSH_OPTS "$SITE_DIR/$f" ${VPS_USER}@${VPS_IP}:/var/www/portage-ai/
        fi
    done
    # Images
    if [ -d "$SITE_DIR/img" ]; then
        sshpass -p "$SSH_PASS" scp $SSH_OPTS -r "$SITE_DIR/img/"* ${VPS_USER}@${VPS_IP}:/var/www/portage-ai/img/
    fi
    echo "✓ Fichiers du site transférés"
else
    echo "⚠ Répertoire source du site non trouvé"
fi

# ─── Transférer les fichiers de déploiement ───────────────────────────
echo ""
echo "▸ Transfert des fichiers Docker Compose..."
DEPLOY_DIR="/home/ubuntu/vps-deploy"

# Twenty CRM
sshpass -p "$SSH_PASS" scp $SSH_OPTS "$DEPLOY_DIR/twenty/docker-compose.yml" ${VPS_USER}@${VPS_IP}:/opt/portage-ai/twenty/

# n8n
sshpass -p "$SSH_PASS" scp $SSH_OPTS "$DEPLOY_DIR/n8n/docker-compose.yml" ${VPS_USER}@${VPS_IP}:/opt/portage-ai/n8n/

# Fire-Enrich
sshpass -p "$SSH_PASS" scp $SSH_OPTS "$DEPLOY_DIR/fire-enrich/docker-compose.yml" ${VPS_USER}@${VPS_IP}:/opt/portage-ai/fire-enrich/

# Nginx config
sshpass -p "$SSH_PASS" scp $SSH_OPTS "$DEPLOY_DIR/nginx/portage-ai.conf" ${VPS_USER}@${VPS_IP}:/opt/portage-ai/

# Script de déploiement
sshpass -p "$SSH_PASS" scp $SSH_OPTS "$DEPLOY_DIR/scripts/deploy-all.sh" ${VPS_USER}@${VPS_IP}:/opt/portage-ai/scripts/

# OpenOutreach
if [ -d "$SITE_DIR/openoutreach-deploy" ]; then
    sshpass -p "$SSH_PASS" scp $SSH_OPTS -r "$SITE_DIR/openoutreach-deploy/"* ${VPS_USER}@${VPS_IP}:/opt/portage-ai/openoutreach/
fi

echo "✓ Fichiers de déploiement transférés"

# ─── Lancer le déploiement sur le VPS ─────────────────────────────────
echo ""
echo "▸ Lancement du déploiement sur le VPS..."
echo "  (cela peut prendre 5-10 minutes)"
echo ""

sshpass -p "$SSH_PASS" ssh $SSH_OPTS ${VPS_USER}@${VPS_IP} << 'DEPLOYCMD'
chmod +x /opt/portage-ai/scripts/deploy-all.sh
sudo bash /opt/portage-ai/scripts/deploy-all.sh
DEPLOYCMD

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ Transfert et déploiement terminés"
echo "═══════════════════════════════════════════════════════════"
