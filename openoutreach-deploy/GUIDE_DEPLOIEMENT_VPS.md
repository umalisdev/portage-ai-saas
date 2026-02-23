# Guide de Déploiement — OpenOutreach sur VPS OVH

## Architecture du système

Le VPS OVH sert de **moteur de scraping et d'enrichissement** qui alimente automatiquement vos deux plateformes :

| Composant | Hébergement | Rôle |
|---|---|---|
| **portagesalarial.ai** | Manus Space | Plateforme principale, CRM, espace consultant |
| **Dashboard GitHub** | GitHub Pages | Tableau de bord commercial, suivi des KPIs |
| **VPS OVH** | France — Roubaix | Scraping LinkedIn, qualification IA, export |

Le flux de données fonctionne ainsi : le VPS scrape LinkedIn en continu, qualifie les profils avec l'IA, puis les envoie automatiquement toutes les heures vers portagesalarial.ai (via API tRPC sécurisée) et vers le dashboard GitHub Pages (via GitHub API).

---

## Prérequis

Avant de commencer, assurez-vous de disposer des éléments suivants :

| Élément | Description |
|---|---|
| **Accès SSH au VPS** | IP : `92.222.243.220`, utilisateur : `ubuntu` |
| **Compte LinkedIn dédié** | Un compte LinkedIn séparé pour la prospection (ne pas utiliser votre compte personnel) |
| **Clé API OpenAI** | Pour la qualification intelligente des profils |
| **Token GitHub** | Pour l'export automatique vers le dashboard |

---

## Étape 1 — Connexion au VPS

Ouvrez un terminal sur votre ordinateur et connectez-vous en SSH :

```bash
ssh ubuntu@92.222.243.220
```

Mot de passe : celui que vous avez défini (ou celui fourni par OVH).

---

## Étape 2 — Lancer le déploiement automatique

Une fois connecté au VPS, exécutez la commande suivante :

```bash
curl -sL https://raw.githubusercontent.com/umalisdev/portage-ai-saas/main/openoutreach-deploy/deploy_vps.sh | bash
```

**Alternative** (si le dépôt GitHub n'est pas encore à jour) : copiez-collez le contenu du fichier `deploy_vps.sh` directement dans le terminal.

Le script effectuera automatiquement les opérations suivantes :

1. Mise à jour du système Ubuntu
2. Installation de Docker et Docker Compose
3. Téléchargement du package OpenOutreach
4. Création du fichier de configuration `.env`
5. Démarrage des services

---

## Étape 3 — Configurer le fichier .env

Le script vous demandera de configurer le fichier `.env`. Ouvrez-le avec :

```bash
nano ~/openoutreach-deploy/.env
```

Renseignez les variables obligatoires suivantes :

```env
# Compte LinkedIn dédié à la prospection
LINKEDIN_USERNAME=votre.email.prospection@gmail.com
LINKEDIN_PASSWORD=votre_mot_de_passe_linkedin

# Clé API OpenAI pour la qualification IA
LLM_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Token GitHub pour l'export vers le dashboard
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Sauvegardez avec `Ctrl+O` puis `Entrée`, et quittez avec `Ctrl+X`.

---

## Étape 4 — Démarrer le scraping

```bash
cd ~/openoutreach-deploy
bash start.sh
```

Les services suivants démarreront :

| Service | Port | Description |
|---|---|---|
| **app** (OpenOutreach) | 3000 | Daemon de scraping LinkedIn |
| **crm** (Django) | 8000 | Interface CRM pour gérer les profils |
| **exporter** | — | Export automatique toutes les heures |

---

## Étape 5 — Vérifier le fonctionnement

Consultez les logs en temps réel :

```bash
# Logs du scraping LinkedIn
docker compose logs -f app

# Logs de l'export vers portagesalarial.ai et GitHub
docker compose logs -f exporter

# Logs du cron d'export
tail -f /var/log/openoutreach/export.log
```

Accédez au CRM Django :

```
http://92.222.243.220:8000/admin/
Login : admin
Mot de passe : admin
```

---

## Commandes utiles

| Commande | Description |
|---|---|
| `docker compose logs -f app` | Suivre les logs du scraping |
| `docker compose logs -f exporter` | Suivre les logs d'export |
| `docker compose restart app` | Redémarrer le scraping |
| `docker compose down` | Arrêter tous les services |
| `docker compose up -d` | Relancer tous les services |
| `python3 export_to_portageai.py` | Forcer un export manuel |
| `nano .env` | Modifier la configuration |

---

## Sécurité

Le système utilise plusieurs couches de sécurité :

| Mesure | Description |
|---|---|
| **Clé API interne** | Générée automatiquement, protège le flux VPS → portagesalarial.ai |
| **Limites LinkedIn** | 20 connexions/jour, 100/semaine pour éviter les restrictions |
| **Token GitHub** | Accès restreint au dépôt pour l'export |
| **Logs d'audit** | Toutes les opérations sont tracées dans `/var/log/openoutreach/` |

---

## Support

En cas de problème, consultez les logs et vérifiez la configuration `.env`. Pour toute question, contactez l'équipe technique via le dashboard ou par email.
