#!/bin/bash
# ─────────────────────────────────────────────────────────────────────
# start.sh — Script de démarrage rapide OpenOutreach + Portage AI
# ─────────────────────────────────────────────────────────────────────
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🚀 OpenOutreach — Portage AI Deployment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker n'est pas installé. Installez Docker d'abord.${NC}"
    echo "   https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose n'est pas installé.${NC}"
    exit 1
fi

# Vérifier le fichier .env
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Fichier .env non trouvé.${NC}"
    echo ""

    if [ -f .env.example ]; then
        echo -e "${BLUE}Création du fichier .env à partir de .env.example...${NC}"
        cp .env.example .env
        echo ""
        echo -e "${YELLOW}📝 Veuillez configurer votre fichier .env :${NC}"
        echo "   nano .env"
        echo ""
        echo "   Variables obligatoires :"
        echo "   - LINKEDIN_USERNAME : email de votre compte LinkedIn dédié"
        echo "   - LINKEDIN_PASSWORD : mot de passe du compte"
        echo "   - LLM_API_KEY      : clé API OpenAI"
        echo ""
        read -p "Appuyez sur Entrée une fois le fichier .env configuré..."
    else
        echo -e "${RED}❌ Fichier .env.example non trouvé.${NC}"
        exit 1
    fi
fi

# Vérifier les variables critiques
source .env 2>/dev/null
if [ -z "$LINKEDIN_USERNAME" ] || [ "$LINKEDIN_USERNAME" = "votre.email@exemple.com" ]; then
    echo -e "${RED}❌ LINKEDIN_USERNAME non configuré dans .env${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuration .env validée${NC}"
echo ""

# Construire et lancer
echo -e "${BLUE}🔨 Construction des images Docker...${NC}"
docker compose build --quiet

echo ""
echo -e "${BLUE}🔧 Initialisation de la base de données...${NC}"
docker compose run --rm init
echo ""

echo -e "${BLUE}🚀 Démarrage des services...${NC}"
docker compose up -d app crm exporter

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ OpenOutreach est lancé !${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  📋 CRM Django     : http://localhost:${CRM_PORT:-8000}/admin/"
echo "     Login          : admin / admin"
echo ""
echo "  🔍 Scraping       : En cours (voir les logs ci-dessous)"
echo "  📊 Export auto    : Toutes les $(( ${EXPORT_INTERVAL:-3600} / 60 )) minutes"
echo ""
echo "  📝 Commandes utiles :"
echo "     docker compose logs -f app        # Logs du scraping"
echo "     docker compose logs -f exporter   # Logs de l'export"
echo "     docker compose exec app shell     # Shell interactif"
echo "     docker compose down               # Arrêter tout"
echo ""
echo -e "${BLUE}Affichage des logs du daemon de scraping...${NC}"
echo ""

docker compose logs -f app
