# Rapport de déploiement — VPS OVH 92.222.243.220

**Date** : 24 février 2026  
**VPS** : vps-1635de67.vps.ovh.net (92.222.243.220)  
**Client** : jl177663-ovh  

---

## 1. Diagnostic de connectivité

### Résultat des tests

| Test | Résultat | Détail |
|:-----|:---------|:-------|
| **Ping ICMP** | OK | 3/3 paquets reçus, latence 0.3-2.4 ms |
| **Port 22 (SSH)** | Ouvert mais bloqué | `kex_exchange_identification: Connection closed by remote host` |
| **Port 80 (HTTP)** | Ouvert, pas de réponse HTTP | TCP ouvert, aucun contenu servi |
| **Port 443 (HTTPS)** | Ouvert, pas de réponse HTTP | TCP ouvert, aucun contenu servi |
| **Port 3000** | Ouvert, pas de réponse HTTP | TCP ouvert, aucun service actif |
| **Port 3001** | Ouvert, pas de réponse HTTP | TCP ouvert, aucun service actif |
| **Port 5678** | Ouvert, pas de réponse HTTP | TCP ouvert, aucun service actif |
| **Connexion SSH (ubuntu)** | Echec | Connexion fermée avant échange de clés |
| **Connexion SSH (root)** | Echec | Même comportement |

### Analyse

Le VPS est **physiquement accessible** sur le réseau (ping OK, ports TCP ouverts) mais le service SSH **refuse les connexions** avant même l'authentification. Ce comportement est caractéristique de l'une des situations suivantes :

1. **Blocage OVH suite à l'attaque DDoS** : Le VPS a été bloqué le 23 février 2026 suite à une attaque UDP DDoS (34Kpps/51Mbps). OVH a pu mettre le serveur en mode "mitigation" ou "rescue" qui bloque SSH.

2. **fail2ban ou iptables** : Notre adresse IP sandbox pourrait être bloquée par fail2ban suite aux tentatives précédentes.

3. **sshd non fonctionnel** : Le service SSH pourrait être dans un état dégradé après le blocage.

### Email envoyé à OVH

Un email de demande de réinstallation a été envoyé à `support@ovh.net` le 23 février 2026 à 22h07 UTC. **Aucune réponse n'a encore été reçue.**

> Contenu de la demande : réinstallation complète avec Ubuntu 24.04 LTS et déblocage du service.

---

## 2. Fichiers préparés pour le déploiement

Tous les fichiers nécessaires au déploiement complet sont prêts dans `/home/ubuntu/vps-deploy/` :

### Structure des fichiers

```
vps-deploy/
├── nginx/
│   └── portage-ai.conf          # Configuration Nginx (site + reverse proxy)
├── twenty/
│   └── docker-compose.yml        # Twenty CRM + PostgreSQL + Redis (port 3000)
├── n8n/
│   └── docker-compose.yml        # n8n + PostgreSQL (port 5678)
├── fire-enrich/
│   └── docker-compose.yml        # Fire-Enrich (port 3001)
├── openoutreach/                  # (vide, fichiers dans le repo GitHub)
├── scripts/
│   ├── deploy-all.sh             # Script de déploiement complet (à exécuter sur le VPS)
│   ├── transfer-and-deploy.sh    # Script de transfert + déploiement depuis Manus
│   └── check-services.sh         # Script de vérification des services
└── RAPPORT-DEPLOIEMENT.md        # Ce rapport
```

### Code source du site web

Le repo GitHub `umalisdev/portage-ai-saas` a été cloné dans `/home/ubuntu/portage-ai-saas/` avec les fichiers suivants :

| Fichier | Description |
|:--------|:------------|
| `index.html` | Page d'accueil du site |
| `dashboard.html` | Tableau de bord |
| `agents.html` | Page des agents IA |
| `tendances-kpis.html` | Tendances et KPIs |
| `presentation-agents.html` | Présentation des agents |
| `recherche-linkedin.html` | Recherche LinkedIn |
| `etude-architecture.html` | Étude d'architecture |
| `implementation-suivi.html` | Suivi d'implémentation |
| `img/` | Images (alex.png, aria.png, luna.png, max.png, noah.png) |
| `openoutreach-deploy/` | Fichiers de déploiement OpenOutreach |

---

## 3. Services à déployer

| Service | Port | Image Docker | Base de données |
|:--------|:-----|:-------------|:----------------|
| **Nginx** (site web) | 80 | N/A (package système) | N/A |
| **Twenty CRM** | 3000 | `twentycrm/twenty:latest` | PostgreSQL + Redis |
| **n8n** | 5678 | `n8nio/n8n:latest` | PostgreSQL |
| **Fire-Enrich** | 3001 | `ghcr.io/nicholasoxford/fire-enrich:latest` | N/A |
| **OpenOutreach** | 8000 | Build local (Dockerfile) | SQLite |

### Identifiants configurés

| Service | Utilisateur | Mot de passe |
|:--------|:------------|:-------------|
| **n8n** | admin@portagesalarial.ai | Landerneau2027@ |
| **OpenOutreach CRM** | admin | admin |
| **Fire-Enrich** | N/A | Clé API Firecrawl: `fc-86b47ffcd30c46ae924d1e3f5a00bda4` |

### Pare-feu UFW

| Port | Service | Protocole |
|:-----|:--------|:----------|
| 22 | SSH | TCP |
| 80 | HTTP (Nginx) | TCP |
| 443 | HTTPS | TCP |
| 3000 | Twenty CRM | TCP |
| 3001 | Fire-Enrich | TCP |
| 5678 | n8n | TCP |

---

## 4. Procédure de déploiement

### Option A — Déploiement automatisé depuis Manus (recommandé)

Dès que le VPS sera accessible via SSH :

```bash
# Depuis le sandbox Manus :
bash /home/ubuntu/vps-deploy/scripts/transfer-and-deploy.sh 'NOUVEAU_MOT_DE_PASSE'
```

### Option B — Déploiement manuel sur le VPS

Si vous avez accès au VPS via la console KVM OVH :

```bash
# 1. Se connecter via la console KVM OVH
# 2. Installer git et cloner le repo
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/umalisdev/portage-ai-saas.git /home/ubuntu/portage-ai-saas

# 3. Copier le script de déploiement
# (le script est auto-contenu et crée tous les fichiers nécessaires)
# Télécharger depuis GitHub ou copier-coller le contenu de deploy-all.sh

# 4. Exécuter le déploiement
sudo bash deploy-all.sh
```

---

## 5. Actions requises

1. **Attendre la réponse d'OVH** concernant la demande de réinstallation et déblocage du VPS
2. **Vérifier l'espace client OVH** pour l'état du VPS et un éventuel nouveau mot de passe
3. **Relancer le déploiement** dès que SSH est accessible avec la commande :
   ```bash
   bash /home/ubuntu/vps-deploy/scripts/transfer-and-deploy.sh 'MOT_DE_PASSE'
   ```
4. **Configurer les identifiants LinkedIn** dans OpenOutreach (fichier `.env`)
5. **Configurer Cloudflare** pour le domaine portagesalarial.ai (DNS + SSL)

---

## 6. Sécurité post-déploiement

Le script de déploiement inclut automatiquement :

- **UFW** : pare-feu configuré avec uniquement les ports nécessaires
- **Fail2ban** : protection contre les attaques par force brute SSH (ban après 3 tentatives)
- **Headers de sécurité Nginx** : X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Compression Gzip** : pour les performances
- **Docker isolé** : les services Docker ne sont pas exposés directement (sauf les ports mappés)
