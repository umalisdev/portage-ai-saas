# OpenOutreach — Déploiement Portage AI

## Architecture

```
OpenOutreach (Scraping LinkedIn)
       │
       ▼
   CRM Django (Leads, Contacts, Deals)
       │
       ▼
export_to_dashboard.py (Script d'intégration)
       │
       ▼
Dashboard Portage AI (dashboard.html)
```

## Prérequis

- Docker et Docker Compose installés
- Un compte LinkedIn dédié à la prospection
- Une clé API OpenAI (ou compatible)

## Installation rapide

```bash
# 1. Cloner et configurer
cp .env.example .env
nano .env  # Remplir les identifiants

# 2. Lancer les services
docker compose up -d

# 3. Initialiser la base de données
docker compose exec app python manage.py migrate
docker compose exec app python manage.py setup_crm
docker compose exec app python manage.py createsuperuser

# 4. Accéder au CRM
# http://localhost:8000/crm/
```

## Commandes utiles

```bash
# Lancer le daemon de scraping LinkedIn
docker compose exec app python manage.py

# Lancer le serveur web CRM
docker compose exec app python manage.py runserver 0.0.0.0:8000

# Exporter les profils vers le dashboard
docker compose exec app python export_to_dashboard.py --inject /dashboard/dashboard.html

# Exporter en JSON
docker compose exec app python export_to_dashboard.py --json -o profiles.json

# Voir les logs
docker compose logs -f app
```

## Script d'intégration (export_to_dashboard.py)

Le script `export_to_dashboard.py` convertit les Leads du CRM OpenOutreach en profils compatibles avec le dashboard Portage AI.

### Fonctionnalités

- **Extraction automatique** des compétences depuis les tags CRM et la description
- **Calcul du score** basé sur la complétude du profil (0-100)
- **Mapping des statuts** CRM → Dashboard (New → Nouveau, Connected → Connecté, etc.)
- **Attribution d'agents IA** rotatifs (ARIA, LUNA, NOAH, ALEX, MAX)
- **Tags sémantiques** pour la recherche multi-critères
- **Injection directe** dans le fichier dashboard.html

### Modes d'utilisation

| Mode | Commande | Description |
|------|---------|-------------|
| JSON | `--json` | Export en format JSON brut |
| JavaScript | (défaut) | Génère du code JS injectable |
| Injection | `--inject dashboard.html` | Remplace directement dans le HTML |

## Sécurité

- Ne jamais committer le fichier `.env` sur Git
- Utiliser un compte LinkedIn dédié (pas votre compte personnel)
- Respecter les limites de connexion quotidiennes (20/jour, 100/semaine)
- Le scraping LinkedIn comporte des risques de suspension de compte
