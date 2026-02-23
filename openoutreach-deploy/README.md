# 🚀 OpenOutreach — Déploiement Portage AI

Ce package contient tout le nécessaire pour déployer **OpenOutreach** sur votre propre serveur avec Docker. Il est pré-configuré pour s'intégrer parfaitement avec le **Dashboard Portage AI**.

## 1. Prérequis

- **Serveur/Machine locale** avec Docker et Docker Compose installés.
- **Compte LinkedIn dédié** à la prospection (pour éviter de bloquer votre compte personnel).
- **Clé API OpenAI** pour la qualification IA des profils.
- **Fichier `dashboard.html`** de votre projet Portage AI SaaS.

## 2. Configuration

1.  **Copiez le fichier `.env.example` en `.env`** :

    ```bash
    cp .env.example .env
    ```

2.  **Modifiez le fichier `.env`** et remplissez les variables :

    | Variable | Description |
    | --- | --- |
    | `LINKEDIN_USERNAME` | Email de votre compte LinkedIn dédié. |
    | `LINKEDIN_PASSWORD` | Mot de passe du compte. |
    | `LLM_API_KEY` | Votre clé API OpenAI (commence par `sk-...`). |
    | `CRM_PORT` | Port pour accéder à l'interface CRM (défaut: 8000). |
    | `EXPORT_INTERVAL` | Intervalle d'export en secondes (défaut: 3600 = 1h). |

3.  **Placez votre `dashboard.html`** dans un répertoire qui sera monté en volume :

    Créez un répertoire `dashboard` à côté de ce `README.md` et placez-y votre fichier `dashboard.html` :

    ```
    openoutreach-deploy/
    ├── dashboard/
    │   └── dashboard.html
    ├── docker-compose.yml
    ├── .env
    └── ...
    ```

## 3. Démarrage

Le script `start.sh` automatise tout le processus (vérification, build, initialisation, démarrage).

```bash
./start.sh
```

Le script va :
1.  Vérifier votre configuration.
2.  Construire les images Docker.
3.  Initialiser la base de données, la campagne et les mots-clés.
4.  Démarrer les 3 services (daemon, crm, exporter).
5.  Afficher les logs du daemon de scraping en temps réel.

## 4. Services

| Service | Description | Accès |
| --- | --- | --- |
| **`app`** | **Daemon de scraping LinkedIn**. Il tourne en arrière-plan, se connecte à LinkedIn et recherche des profils. | `docker compose logs -f app` |
| **`crm`** | **Interface web du CRM Django**. Permet de voir les leads, les campagnes, les stats. | `http://localhost:8000/admin/` (login: `admin` / pass: `admin`) |
| **`exporter`** | **Export automatique**. Toutes les heures, il exporte les profils du CRM et les injecte dans votre `dashboard.html`. | `docker compose logs -f exporter` |

## 5. Commandes utiles

- **Voir les logs du scraping** :
  ```bash
  docker compose logs -f app
  ```

- **Voir les logs de l'export** :
  ```bash
  docker compose logs -f exporter
  ```

- **Arrêter tous les services** :
  ```bash
  docker compose down
  ```

- **Lancer un export manuel** :
  ```bash
  docker compose run --rm export-once
  ```

- **Ouvrir un shell dans le conteneur `app`** :
  ```bash
  docker compose exec app shell
  ```

## 6. Dépannage

- **Erreur "Login failed – no redirect to feed"** : LinkedIn a détecté une connexion depuis une nouvelle IP et demande une vérification (CAPTCHA, email, SMS). Pour résoudre cela, vous pouvez utiliser un VNC pour vous connecter manuellement au navigateur dans le conteneur et passer le checkpoint. Une fois fait, les cookies de session seront sauvegardés et le scraping pourra continuer.

- **Le scraping ne trouve aucun profil** : Vérifiez les mots-clés de recherche dans le CRM (`http://localhost:8000/admin/linkedin/searchkeyword/`) et ajustez-les si nécessaire.
