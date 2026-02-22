# Rapport d'Audit — Simulateur de Portage Commercial
## Intégration dans la Plateforme Portage AI Sales Force Command Center

**Auteur** : Manus AI
**Date** : 22 février 2026
**Objet** : Audit technique et fonctionnel du logiciel *simulateur-portage-main_commercial* et recommandations d'intégration dans la plateforme SaaS unifiée avec équipe commerciale IA

---

## 1. Synthèse exécutive

Le projet audité est une plateforme de portage salarial complète, développée en TypeScript avec une architecture full-stack (React + Vite côté client, Express + tRPC côté serveur, MySQL via Drizzle ORM). Le projet totalise **212 fichiers source**, environ **57 500 lignes de code** et **330+ tests unitaires**, ce qui témoigne d'un niveau de maturité significatif.

L'objectif de cet audit est d'identifier comment ce socle métier s'articule avec l'équipe commerciale IA (agents ARIA, NOAH, LUNA, ALEX, MAX) pour former un **écosystème SaaS cohérent** où les agents IA pilotent automatiquement les fonctionnalités commerciales de la plateforme.

---

## 2. Architecture technique

### 2.1 Stack technologique

| Couche | Technologies | Maturité |
|--------|-------------|----------|
| **Frontend** | React 19, Vite, Tailwind CSS, Recharts, Shadcn/UI | Élevée |
| **Backend** | Express, tRPC (22 routeurs modulaires), Node.js | Élevée |
| **Base de données** | MySQL, Drizzle ORM, pool de connexions avec retry | Élevée |
| **IA / LLM** | Grok API (xAI), LEA (assistant conversationnel) | Opérationnelle |
| **Intégrations** | LinkedIn StaffSpy, Hunter.io, Gmail MCP, S3 | Opérationnelle |
| **Tests** | Vitest, 330+ tests unitaires | Très bonne couverture |

### 2.2 Architecture des routeurs tRPC (22 modules)

Le backend est organisé en routeurs modulaires spécialisés, chacun correspondant à un domaine fonctionnel distinct :

| Routeur | Domaine | Pertinence pour les agents IA |
|---------|---------|-------------------------------|
| `simulations` | Calcul et historique des simulations | ARIA (prospection) |
| `crm` | Gestion des prospects et pipeline | NOAH (qualification B2B) |
| `prospect` | Bureau virtuel des consultants | LUNA (fidélisation) |
| `linkedin` | Recherche et enrichissement LinkedIn | ALEX (LinkedIn) |
| `campaigns` | Campagnes d'emailing en masse | MAX (marketing) |
| `grok` | Analyse de marché et optimisation IA | Tous les agents |
| `leaConversations` | Assistant conversationnel LEA | Support transversal |
| `marketAnalysis` | Analyse de marché persistante | NOAH, ALEX |
| `notifications` | Notifications consultants | LUNA |
| `adminNotifications` | Alertes administrateurs | Supervision |
| `emailTemplates` | Templates d'emails personnalisables | MAX |
| `contactRequests` | Demandes de contact et formulaires | ARIA |
| `userManagement` | Gestion des utilisateurs et rôles | Administration |
| `weeklyReport` | Rapports hebdomadaires automatiques | Reporting |
| `rates` | Gestion des taux de simulation | Configuration |
| `invitations` | Système d'invitation consultants | ARIA, LUNA |
| `pwa` | Statistiques PWA | Analytics |
| `dbHealth` | Santé de la base de données | Monitoring |
| `contact` | Formulaire de contact | ARIA |
| `shared` | Utilitaires partagés | Transversal |

---

## 3. Modules fonctionnels identifiés

### 3.1 Simulateur de revenus (module central)

Le simulateur constitue le **coeur métier** de la plateforme. Il implémente un moteur de calcul sophistiqué utilisant la **méthode de dichotomie (bisection)** pour résoudre l'équation brut/enveloppe salariale, avec prise en charge des charges sociales cadre et non-cadre 2024.

**Fonctionnalités clés** :
- Calcul TJM → salaire net avec barème dégressif des frais de gestion (2% à 5% selon le CA)
- Simulation inversée (salaire brut → TJM)
- Détail ligne par ligne des charges sociales (patronales et salariales)
- Indemnités kilométriques (barème fiscal 2024)
- Provision congés payés, PEE/PERCO
- Génération PDF des résultats
- Mémorisation et pré-remplissage des paramètres

> **Recommandation d'intégration** : L'agent **ARIA** utilise ce simulateur pour générer automatiquement des propositions personnalisées lors de la prospection. Chaque simulation déclenche la création d'une fiche CRM et l'attribution automatique à un commercial (pair/impair).

### 3.2 CRM et pipeline commercial

Le CRM intégré gère le cycle de vie complet des prospects avec 7 statuts (nouveau, contacté, en discussion, proposition envoyée, gagné, perdu, inactif), un système de priorité, des tags, et un historique complet des interactions.

**Fonctionnalités clés** :
- Création automatique de fiches prospects lors des simulations
- Attribution automatique aux commerciaux (Célia/Paulette, pair/impair)
- Système de rappels automatiques avec dates de relance
- Filtres avancés (statut, commercial, date, CA potentiel)
- Tri et pagination des listes
- Export CSV avec formatage français

> **Recommandation d'intégration** : L'agent **NOAH** pilote le pipeline B2B en qualifiant automatiquement les prospects, en déclenchant les relances et en mettant à jour les statuts CRM en fonction des interactions détectées.

### 3.3 Bureau virtuel des consultants

Chaque consultant dispose d'un espace personnel avec historique de simulations, profil LinkedIn, upload de CV, comparaison de simulations, et accès à l'assistant LEA.

**Fonctionnalités clés** :
- Création automatique lors de la première simulation
- Historique chronologique des simulations avec comparaison côte à côte
- Duplication de simulations
- Profil LinkedIn synchronisé
- Upload et aperçu PDF du CV
- Notifications personnalisées
- Optimisation IA des revenus

> **Recommandation d'intégration** : L'agent **LUNA** gère la relation avec les consultants existants via le bureau virtuel, en proposant des optimisations de revenus et en maintenant l'engagement.

### 3.4 Intégration LinkedIn (StaffSpy)

Le module LinkedIn permet la recherche de profils par entreprise ou par poste, avec enrichissement des emails via Hunter.io et import automatique dans le CRM.

**Fonctionnalités clés** :
- Recherche de profils LinkedIn par entreprise ou poste
- Enrichissement automatique des emails (Hunter.io)
- Vérification de validité des emails
- Import vers le CRM en un clic
- Système de favoris et notes
- Statistiques de recherche

> **Recommandation d'intégration** : L'agent **ALEX** exploite ce module pour identifier et qualifier des prospects sur LinkedIn, enrichir leurs données et les injecter dans le pipeline B2B.

### 3.5 Campagnes d'emailing

Le système de campagnes permet la création, la programmation et le suivi de campagnes email en masse avec templates personnalisables.

**Fonctionnalités clés** :
- Création de campagnes avec templates personnalisables
- Ajout de destinataires depuis les recherches LinkedIn
- Programmation d'envoi différé
- Suivi des statuts (envoyé, ouvert, cliqué, rebondi)
- Aperçu visuel avant envoi
- Variables dynamiques dans les templates

> **Recommandation d'intégration** : L'agent **MAX** orchestre les campagnes marketing en sélectionnant les templates appropriés, en ciblant les segments pertinents et en optimisant les taux d'ouverture.

### 3.6 Assistant LEA (IA conversationnelle)

LEA est un assistant IA intégré utilisant Grok, spécialisé dans le portage salarial, avec historique de conversations persistant et simulations rapides dans le chat.

**Fonctionnalités clés** :
- Chat conversationnel avec connaissances métier Light Portage
- Simulations rapides dans le chat (TJM → salaire net)
- Suggestions contextuelles basées sur le profil consultant
- Historique des conversations avec archivage
- Export des conversations

### 3.7 Analyse de marché (Grok)

Le module d'analyse de marché utilise Grok pour évaluer le potentiel commercial d'un consultant en fonction de ses compétences et de son profil LinkedIn.

**Fonctionnalités clés** :
- Analyse automatique basée sur le profil LinkedIn
- Évaluation du potentiel de marché (secteurs, TJM, tendances)
- Persistance des analyses en base de données
- Historique avec versioning
- Intégration dans le bureau virtuel et l'admin

### 3.8 Optimisation IA des revenus

Ce module analyse le profil financier d'un consultant et propose des recommandations personnalisées pour optimiser sa rémunération nette.

**Fonctionnalités clés** :
- Analyse de rentabilité avec graphiques (anneau, barres, jauges)
- Comparaison avant/après optimisation
- Recommandations personnalisées (frais, épargne, TJM)
- Tracking des analyses (logs, statistiques)
- Notifications automatiques pour les optimisations potentielles

---

## 4. Schéma de base de données

Le schéma comprend **17+ tables** couvrant l'ensemble des domaines fonctionnels :

| Table | Rôle | Enregistrements typiques |
|-------|------|--------------------------|
| `users` | Authentification OAuth | Administrateurs |
| `simulation_rates` | Taux de calcul paramétrables | ~20 taux |
| `simulation_history` | Historique des simulations | Croissance continue |
| `prospects` | Comptes bureau virtuel | Consultants |
| `prospect_crm` | Fiches CRM commerciales | Pipeline |
| `crm_interactions` | Journal des interactions | Historique |
| `ai_optimization_logs` | Tracking optimisations IA | Analytics |
| `consultant_notifications` | Notifications consultants | Alertes |
| `admin_notifications` | Notifications admin | Alertes |
| `email_templates` | Templates emails | ~10 templates |
| `email_template_history` | Historique modifications | Audit |
| `email_campaigns` | Campagnes emailing | Campagnes |
| `email_campaign_recipients` | Destinataires campagnes | Contacts |
| `linkedin_searches` | Recherches LinkedIn | Recherches |
| `linkedin_profiles` | Profils LinkedIn | Prospects |
| `contact_requests` | Demandes de contact | Leads |
| `lea_conversations` / `lea_messages` | Historique LEA | Conversations |
| `market_analyses` | Analyses de marché | Analyses |
| `invitations` | Invitations consultants | Invitations |
| `pwa_events` | Statistiques PWA | Events |

---

## 5. Cartographie de l'écosystème unifié

L'articulation entre les agents IA et les modules du simulateur forme un écosystème cohérent :

```
┌─────────────────────────────────────────────────────────────────┐
│                PORTAGE AI — SALES FORCE COMMAND CENTER          │
│                        (Site Web SaaS)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────┐│
│  │  ARIA   │  │  NOAH   │  │  LUNA   │  │  ALEX   │  │ MAX  ││
│  │Prospect.│  │Qualif.  │  │Fidélis. │  │LinkedIn │  │Market││
│  │ B2C     │  │ B2B     │  │Consult. │  │Outreach │  │ ing  ││
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └──┬───┘│
│       │            │            │            │           │     │
│  ┌────▼────────────▼────────────▼────────────▼───────────▼───┐│
│  │              MOTEUR MÉTIER (Simulateur)                    ││
│  │  Simulateur revenus │ CRM │ Bureau virtuel │ LEA │ Grok  ││
│  │  Campagnes email │ LinkedIn │ Optimisation IA │ Analytics ││
│  └───────────────────────────────────────────────────────────┘│
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐│
│  │              BASE DE DONNÉES (MySQL / Drizzle)            ││
│  │  17+ tables │ Pool connexions │ Health check │ Retry      ││
│  └───────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Recommandations d'intégration prioritaires

### 6.1 Fonctionnalités à intégrer dans le site SaaS (priorité haute)

| Priorité | Fonctionnalité | Agent IA concerné | Complexité |
|----------|---------------|-------------------|------------|
| 1 | Simulateur de revenus (TJM → net + inversé) | ARIA | Moyenne |
| 2 | CRM avec pipeline et statuts | NOAH, ARIA | Élevée |
| 3 | Dashboard analytique avec graphiques | Tous | Moyenne |
| 4 | Optimisation IA des revenus | LUNA, LEA | Moyenne |
| 5 | Campagnes emailing avec templates | MAX | Moyenne |
| 6 | Intégration LinkedIn (recherche + enrichissement) | ALEX | Élevée |
| 7 | Bureau virtuel consultants | LUNA | Élevée |
| 8 | Notifications automatiques (admin + consultants) | Tous | Faible |
| 9 | Rapports hebdomadaires automatiques | Supervision | Faible |
| 10 | Analyse de marché (Grok) | NOAH, ALEX | Moyenne |

### 6.2 Architecture recommandée pour le site SaaS

Le site web SaaS doit adopter une **architecture à navigation latérale** (sidebar) avec les sections suivantes :

1. **Dashboard** — Vue d'ensemble avec KPI, graphiques, activité des agents
2. **Agents IA** — Profils, statuts, métriques et missions de chaque agent
3. **Pipeline B2B** — Prospects entreprises, funnel, CRM
4. **Pipeline B2C** — Prospects consultants, simulations, bureau virtuel
5. **Simulateur** — Simulateur de revenus intégré (standard + inversé)
6. **Campagnes** — Gestion des campagnes email
7. **LinkedIn** — Recherche et enrichissement de profils
8. **Missions** — Création et suivi des missions assignées aux agents
9. **Configuration** — Paramètres, taux, barèmes, intégrations

---

## 7. Conclusion

Le simulateur de portage commercial audité constitue un **socle métier mature et robuste** avec une couverture fonctionnelle très complète. L'intégration avec l'équipe commerciale IA (5 agents spécialisés) permet de créer un **écosystème SaaS unique** où chaque agent exploite les modules métier de manière autonome et coordonnée.

La création du site web SaaS unifié permettra de centraliser l'ensemble de ces fonctionnalités dans une interface professionnelle, avec une navigation intuitive et un dashboard de pilotage en temps réel de l'activité commerciale automatisée.

---

*Rapport généré par Manus AI — 22 février 2026*
