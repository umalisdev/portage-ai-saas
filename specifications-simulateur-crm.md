# Spécifications Techniques — Intégration Simulateur / CRM

**Projet :** Portage AI — Sales Force Command Center  
**Version :** 1.0  
**Date :** 22 février 2026  
**Auteur :** Manus AI

---

## 1. Contexte et objectif

La plateforme Portage AI Sales Force Command Center est un logiciel SaaS destiné à piloter une équipe de 5 agents commerciaux IA (ARIA, NOAH, LUNA, ALEX, MAX) spécialisés dans la prospection, la négociation, le marketing, l'onboarding et l'analytics pour une société de portage salarial. Le simulateur de revenus permet aux prospects de calculer leur salaire net en portage salarial à partir de leur TJM (Taux Journalier Moyen).

L'objectif de cette intégration est d'automatiser la création d'une fiche prospect dans le CRM intégré à chaque fois qu'un utilisateur effectue une simulation de revenus, afin de transformer chaque simulation en opportunité commerciale exploitable par les agents IA.

---

## 2. Architecture actuelle

### 2.1 Stack technique

Le site SaaS est actuellement construit comme une **application web monopage (SPA)** en HTML/CSS/JavaScript pur, avec Chart.js pour les graphiques. L'ensemble du code réside dans un fichier `index.html` unique de 1 263 lignes (76 Ko). Les données sont gérées côté client en mémoire JavaScript (pas de backend ni de base de données persistante).

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| Frontend | HTML5 / CSS3 / JavaScript ES6 | Interface utilisateur SPA |
| Graphiques | Chart.js 4.x | Barres de performance hebdomadaire |
| Icônes | Material Icons Round | Iconographie de l'interface |
| Typographie | Inter (Google Fonts) | Police principale |
| Hébergement | Serveur HTTP statique | Servir le fichier HTML |

### 2.2 Modules existants

Le simulateur comporte deux modes de calcul et le CRM est un module de stockage en mémoire côté client.

**Simulateur Standard (TJM → Salaire Net)** : L'utilisateur saisit son TJM, le nombre de jours travaillés par mois et ses frais professionnels. Le calcul applique le barème Light Portage avec 5 % de frais de gestion, 42 % de charges patronales, et 22 % de charges salariales. Le résultat affiche le salaire net mensuel estimé avec le détail complet (CA HT, frais de gestion, charges patronales, salaire brut, charges salariales, net après PAS, frais professionnels).

**Simulateur Inversé (Salaire → TJM)** : L'utilisateur saisit le salaire net souhaité et le nombre de jours travaillés. Le système calcule le TJM nécessaire en inversant la formule du barème.

**CRM intégré** : Le module CRM stocke les fiches prospects dans un tableau JavaScript `CRM_PROSPECTS` en mémoire. Chaque fiche contient les coordonnées du prospect, les résultats de simulation, l'agent IA assigné, un score de qualification et l'historique des simulations.

---

## 3. Flux d'intégration Simulateur → CRM

### 3.1 Diagramme de flux

Le processus complet se déroule en 7 étapes séquentielles, depuis la saisie du formulaire jusqu'à la notification de l'administrateur.

| Étape | Action | Déclencheur | Résultat |
|-------|--------|-------------|----------|
| 1 | Saisie du formulaire | Utilisateur | Données nominatives + paramètres de simulation |
| 2 | Validation des champs obligatoires | Clic sur « Calculer et créer fiche CRM » | Vérification nom, email, téléphone |
| 3 | Calcul de la simulation | Validation réussie | Résultats financiers (CA, charges, net) |
| 4 | Création de la fiche prospect | Calcul terminé | Objet prospect avec toutes les données |
| 5 | Affectation d'un agent IA | Création de la fiche | Agent assigné par rotation (LUNA → ALEX → ARIA) |
| 6 | Injection dans le pipeline B2C | Affectation agent | Nouveau prospect au stade « Simulation » |
| 7 | Notification toast + mise à jour badge CRM | Injection pipeline | Confirmation visuelle à l'utilisateur |

### 3.2 Données collectées par le formulaire

Le formulaire du simulateur standard collecte les données suivantes avant de déclencher la création de la fiche CRM.

| Champ | Type HTML | ID | Obligatoire | Validation |
|-------|-----------|-----|-------------|------------|
| Prénom | `text` | `sim-prenom` | Non | Chaîne libre |
| Nom | `text` | `sim-nom` | Oui | Non vide |
| Email | `email` | `sim-email` | Oui | Format email valide |
| Téléphone | `tel` | `sim-tel` | Oui | Non vide |
| TJM (€/jour) | `number` | `sim-tjm` | Oui | Nombre > 0, défaut 550 |
| Jours travaillés/mois | `number` | `sim-jours` | Oui | Nombre > 0, défaut 18 |
| Frais professionnels (€/mois) | `number` | `sim-frais` | Non | Nombre ≥ 0, défaut 0 |

### 3.3 Algorithme de calcul du simulateur

Le calcul du salaire net suit le barème Light Portage avec les coefficients suivants :

```
CA HT = TJM × Jours travaillés
Frais de gestion = CA HT × 5%
CA net de gestion = CA HT − Frais de gestion
Charges patronales = CA net de gestion × 42%
Salaire brut = CA net de gestion − Charges patronales
Charges salariales = Salaire brut × 22%
Salaire net = Salaire brut − Charges salariales
Net après PAS = Salaire net × (1 − taux PAS)
Salaire net final = Salaire net + Frais professionnels
```

> **Note :** La formule simplifiée utilisée pour le score CRM est `salaireNet = CA HT × 0.95 × 0.58 × 0.78`, ce qui correspond à la chaîne de coefficients (1 − 5%) × (1 − 42%) × (1 − 22%).

---

## 4. Structure de la fiche prospect CRM

### 4.1 Schéma de données

Chaque fiche prospect créée automatiquement après une simulation contient les champs suivants :

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `id` | `number` | Identifiant auto-incrémenté | `1` |
| `prenom` | `string` | Prénom du prospect | `"Jean"` |
| `nom` | `string` | Nom du prospect | `"Dupont"` |
| `email` | `string` | Adresse email | `"jean.dupont@email.com"` |
| `tel` | `string` | Numéro de téléphone | `"06 12 34 56 78"` |
| `tjm` | `number` | TJM saisi (€/jour) | `550` |
| `jours` | `number` | Jours travaillés/mois | `18` |
| `caHT` | `number` | Chiffre d'affaires HT mensuel | `9900` |
| `salaireNet` | `number` | Salaire net estimé | `4255` |
| `agent` | `string` | ID de l'agent IA assigné | `"alex"` |
| `date` | `string` | Date de création (JJ/MM/AAAA) | `"22/02/2026"` |
| `heure` | `string` | Heure de création (HH:MM) | `"18:44"` |
| `status` | `string` | Statut dans le pipeline | `"simulation"` |
| `score` | `number` | Score de qualification (0-99) | `85` |
| `simulations` | `array` | Historique des simulations | `[{date, tjm, jours, salaireNet}]` |

### 4.2 Algorithme de scoring

Le score de qualification du prospect est calculé automatiquement selon la formule :

```
score = min(99, 50 + TJM/20 + Jours × 2)
```

Ce score reflète le potentiel commercial du prospect : un TJM élevé et un nombre de jours travaillés important augmentent le score. Le plafond est fixé à 99 pour réserver le score 100 aux clients signés.

| TJM | Jours | Score | Interprétation |
|-----|-------|-------|----------------|
| 400 | 15 | 100 → 99 | Prospect très qualifié |
| 550 | 18 | 114 → 99 | Prospect premium |
| 300 | 10 | 85 | Prospect standard |
| 200 | 8 | 76 | Prospect à qualifier |

### 4.3 Algorithme d'affectation des agents IA

L'affectation des agents aux nouveaux prospects suit une **rotation circulaire** entre trois agents spécialisés dans le parcours B2C :

| Tour | Agent | Spécialité | Justification |
|------|-------|------------|---------------|
| 1 | LUNA | Marketing & Nurturing | Premier contact, séquences email automatisées |
| 2 | ALEX | Onboarding & Fidélisation | Accompagnement personnalisé du prospect |
| 3 | ARIA | Prospection & Qualification | Qualification approfondie du profil |

La rotation est déterminée par `agents[simCounter % 3]` où `simCounter` est le compteur global de simulations. NOAH (Négociation) et MAX (Analytics) ne sont pas inclus dans la rotation car ils interviennent plus tard dans le cycle de vente.

---

## 5. Intégration avec le pipeline B2C

### 5.1 Injection automatique

À chaque création de fiche CRM, un nouveau prospect est automatiquement injecté dans le pipeline B2C au stade « Simulation ». L'objet inséré dans le tableau `B2C_PIPELINE` contient :

| Champ | Valeur | Source |
|-------|--------|--------|
| `name` | `"Prénom Nom"` | Formulaire simulateur |
| `sector` | `"Simulation"` | Valeur fixe |
| `stage` | `"Simulation"` | Stade initial du funnel B2C |
| `value` | TJM du prospect | Formulaire simulateur |
| `agent` | ID de l'agent assigné | Algorithme de rotation |

### 5.2 Parcours du prospect dans le funnel B2C

Le prospect créé par le simulateur entre au stade « Simulation » et progresse ensuite dans le funnel B2C selon les actions des agents IA :

| Stade | Description | Agent principal | Action requise |
|-------|-------------|-----------------|----------------|
| Contact | Premier contact identifié | LUNA / ARIA | Scraping LinkedIn, formulaire web |
| Simulation | Simulation de revenus effectuée | LUNA | Envoi résultats, séquence nurturing |
| Qualification | Profil validé et intéressé | ARIA | Scoring IA, vérification profil |
| Onboarding | Processus d'inscription en cours | ALEX | Accompagnement, documents |
| Signé | Contrat de portage signé | ALEX | Activation du compte consultant |

---

## 6. Notifications et retours visuels

### 6.1 Toast de confirmation

Après la création réussie d'une fiche CRM, une notification toast apparaît en haut à droite de l'écran pendant 4 secondes avec le message : **« Fiche CRM créée — [Prénom Nom] assigné à [emoji] [AGENT] »**. En cas d'erreur de validation (champs obligatoires manquants), un toast rouge s'affiche avec le message : **« Erreur — Veuillez remplir nom, email et téléphone »**.

### 6.2 Badge CRM dynamique

Le badge numérique dans la sidebar à côté de l'entrée « CRM » est mis à jour en temps réel à chaque nouvelle fiche créée. Il affiche le nombre total de prospects dans le CRM via la fonction `updateCRMBadge()`.

### 6.3 Résultats de simulation

Les résultats détaillés de la simulation s'affichent directement sous le formulaire avec le salaire net en grand format et le détail ventilé (CA HT, frais de gestion, charges patronales, salaire brut, charges salariales, net après PAS, frais professionnels).

---

## 7. Page CRM — Consultation des fiches

### 7.1 Liste des prospects

La page CRM affiche la liste de tous les prospects générés par le simulateur, triés par date de création décroissante (le plus récent en premier). Chaque fiche affiche un avatar avec les initiales, le nom complet, l'email, le téléphone, le score de qualification, les tags (TJM, salaire net, agent assigné, statut), la date de création et l'historique des simulations.

### 7.2 Recherche et filtrage

Un champ de recherche en haut de la page permet de filtrer les prospects par nom, email ou téléphone. La fonction `filterCRM(query)` effectue une recherche insensible à la casse sur les champs `nom`, `prenom`, `email` et `tel`.

---

## 8. Évolutions recommandées pour la version de production

### 8.1 Persistance des données

L'implémentation actuelle stocke les données en mémoire JavaScript. Pour une version de production, les évolutions suivantes sont nécessaires :

| Priorité | Évolution | Description |
|----------|-----------|-------------|
| **P0** | Base de données PostgreSQL | Stocker les fiches prospects, simulations et pipeline de manière persistante |
| **P0** | API REST / tRPC backend | Créer des endpoints serveur pour les opérations CRUD sur les prospects |
| **P0** | Authentification admin | Protéger l'accès au dashboard et au CRM par un système de login |
| **P1** | Bureau Virtuel consultant | Espace privé où chaque prospect retrouve son historique de simulations |
| **P1** | Génération PDF | Permettre le téléchargement d'un rapport PDF détaillé de la simulation |
| **P1** | Envoi email automatique | Envoyer les résultats de simulation par email au prospect |
| **P2** | Notifications push admin | Alerter l'administrateur en temps réel lors de nouvelles simulations |
| **P2** | Séquences de nurturing | Déclencher des campagnes email automatiques après simulation |
| **P2** | Optimisation IA des revenus | Recommandations personnalisées pour maximiser le salaire net |

### 8.2 Schéma de base de données cible

Pour la migration vers une base de données relationnelle, le schéma suivant est recommandé :

```sql
-- Table des prospects
CREATE TABLE prospects (
  id            SERIAL PRIMARY KEY,
  prenom        VARCHAR(100),
  nom           VARCHAR(100) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  telephone     VARCHAR(20) NOT NULL,
  agent_id      VARCHAR(10) REFERENCES agents(id),
  score         INTEGER DEFAULT 0 CHECK (score BETWEEN 0 AND 99),
  status        VARCHAR(20) DEFAULT 'simulation',
  created_at    TIMESTAMP DEFAULT NOW(),
  updated_at    TIMESTAMP DEFAULT NOW()
);

-- Table des simulations
CREATE TABLE simulations (
  id            SERIAL PRIMARY KEY,
  prospect_id   INTEGER REFERENCES prospects(id) ON DELETE CASCADE,
  tjm           NUMERIC(10,2) NOT NULL,
  jours         INTEGER NOT NULL,
  frais_pro     NUMERIC(10,2) DEFAULT 0,
  ca_ht         NUMERIC(12,2) NOT NULL,
  salaire_net   NUMERIC(10,2) NOT NULL,
  mode          VARCHAR(10) DEFAULT 'standard', -- 'standard' ou 'inverse'
  created_at    TIMESTAMP DEFAULT NOW()
);

-- Table des agents IA
CREATE TABLE agents (
  id            VARCHAR(10) PRIMARY KEY,
  name          VARCHAR(50) NOT NULL,
  role          VARCHAR(100),
  emoji         VARCHAR(10),
  color         VARCHAR(7),
  status        VARCHAR(20) DEFAULT 'active',
  score         INTEGER DEFAULT 0
);

-- Table du pipeline
CREATE TABLE pipeline_entries (
  id            SERIAL PRIMARY KEY,
  prospect_id   INTEGER REFERENCES prospects(id),
  type          VARCHAR(3) NOT NULL, -- 'b2b' ou 'b2c'
  stage         VARCHAR(50) NOT NULL,
  value         NUMERIC(12,2),
  agent_id      VARCHAR(10) REFERENCES agents(id),
  created_at    TIMESTAMP DEFAULT NOW(),
  updated_at    TIMESTAMP DEFAULT NOW()
);
```

### 8.3 Endpoints API recommandés

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/simulations` | Effectuer une simulation et créer la fiche prospect |
| `GET` | `/api/prospects` | Lister les prospects avec pagination et filtres |
| `GET` | `/api/prospects/:id` | Détail d'un prospect avec historique |
| `PATCH` | `/api/prospects/:id` | Mettre à jour le statut ou l'agent assigné |
| `DELETE` | `/api/prospects/:id` | Supprimer une fiche prospect |
| `GET` | `/api/prospects/:id/simulations` | Historique des simulations d'un prospect |
| `GET` | `/api/dashboard/kpis` | Métriques du dashboard en temps réel |
| `GET` | `/api/pipeline/:type` | Pipeline B2B ou B2C avec filtres |

---

## 9. Résumé

L'intégration simulateur-CRM est actuellement fonctionnelle côté client avec les caractéristiques suivantes : collecte automatique des coordonnées du prospect lors de la simulation, calcul du salaire net selon le barème Light Portage (5 % frais de gestion, 42 % charges patronales, 22 % charges salariales), création automatique d'une fiche prospect avec scoring et affectation d'agent par rotation, injection dans le pipeline B2C au stade « Simulation », et notification visuelle de confirmation. La prochaine étape majeure consiste à migrer cette logique vers un backend avec base de données persistante pour permettre un usage en production multi-utilisateurs.
