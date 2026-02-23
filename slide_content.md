# Présentation Stratégique — Architecture de Prospection Portage AI

**Style visuel** : Thème sombre professionnel (fond noir/bleu foncé), accents colorés par brique (bleu LinkedIn, orange Fire-Enrich, noir/blanc Twenty, violet n8n). Icônes Material Design. Graphiques et schémas modernes.

---

## Slide 1 — Titre
**Heading** : Architecture de Prospection Open Source — Portage AI
**Sous-titre** : Recommandation stratégique pour la force commerciale
**Contexte** : Portage AI — Sales Force Command Center | Février 2026
**Visuel** : Les 4 logos/icônes des briques alignés en bas : OpenOutreach, Fire-Enrich, Twenty CRM, n8n

---

## Slide 2 — Le défi de la prospection B2B en portage salarial
**Heading** : La prospection manuelle coûte 68% du temps commercial sans garantie de résultat
**Points clés** :
- Le marché du portage salarial en France représente 2,4 Mds€ et croît de 20% par an, créant une concurrence intense pour attirer les consultants qualifiés.
- Les équipes commerciales passent en moyenne 68% de leur temps sur des tâches répétitives (recherche de profils, qualification, relances) au lieu de la négociation et du closing.
- Les outils SaaS propriétaires (LinkedIn Sales Navigator, Apollo, Clay) coûtent entre 59€ et 500€/utilisateur/mois, avec des données enfermées dans des silos.
- L'approche open source permet de reprendre le contrôle sur les données, réduire les coûts de 90% et personnaliser chaque brique selon les besoins métier du portage.

---

## Slide 3 — Vue d'ensemble de l'architecture modulaire
**Heading** : 4 briques open source complémentaires forment un pipeline de prospection automatisé de bout en bout
**Schéma du pipeline** (flux gauche → droite) :
1. **OpenOutreach** (bleu #0077b5) → Découverte & scraping LinkedIn
2. **Fire-Enrich** (orange #f59e0b) → Enrichissement IA des profils
3. **Twenty CRM** (bleu #3b82f6) → Centralisation & gestion des leads
4. **n8n** (violet #8b5cf6) → Orchestration & automatisation des flux

**Texte** : Chaque brique est indépendante et remplaçable. L'ensemble forme un écosystème cohérent où les données circulent automatiquement de la découverte LinkedIn jusqu'au suivi CRM, orchestré par n8n.

---

## Slide 4 — Brique 1 : OpenOutreach — Scraping LinkedIn intelligent
**Heading** : OpenOutreach automatise la découverte et la qualification de profils LinkedIn avec du Machine Learning
**Sous-titre** : github.com/eracle/OpenOutreach | Python, Playwright, Django | Open Source
**Contenu** :
- **Daemon 24/7** : Un moteur central tourne en permanence avec 5 lanes prioritaires (Connect, Check Pending, Follow Up, Enrich, Qualify, Search) qui s'exécutent selon un système de priorités dynamiques.
- **Qualification ML** : Un Gaussian Process Classifier couplé à l'algorithme BALD (Bayesian Active Learning by Disagreement) apprend continuellement quels profils ont le plus de chances de convertir, améliorant la précision à chaque interaction.
- **Machine d'état** : Chaque profil traverse 7 états (Discovered → Enriched → Qualified → Pending → Connected → Completed / Disqualified), assurant une traçabilité complète du parcours.
- **Anti-détection** : Utilisation de Playwright en mode stealth avec rotation de sessions, respect des rate limits LinkedIn (20 connexions/jour, 100/semaine configurable).
- **Messages personnalisés** : Templates Jinja2 avec variables dynamiques (nom, poste, entreprise, compétences) pour des approches hyper-ciblées.

---

## Slide 5 — Brique 2 : Fire-Enrich — Enrichissement IA multi-agents
**Heading** : Fire-Enrich transforme une simple liste d'emails en datasets riches grâce à 4 agents IA spécialisés
**Sous-titre** : github.com/firecrawl/fire-enrich | 1 100+ stars | Alternative open source à Clay ($149/mois)
**Contenu** :
- **Company Research Agent** : Identifie l'industrie, la localisation, la taille de l'entreprise et la description d'activité en crawlant le web avec Firecrawl.
- **Fundraising Intelligence Agent** : Détecte les levées de fonds, montants, investisseurs et stade de financement pour qualifier le potentiel économique.
- **People & Leadership Agent** : Trouve les fondateurs, dirigeants clés et décideurs pour cibler les bons interlocuteurs.
- **Product & Technology Agent** : Analyse la stack technique et les produits principaux pour personnaliser l'approche commerciale.
- **Coût** : Gratuit en self-hosted, seul le coût API OpenAI s'applique (0,01€ à 0,05€ par enrichissement), soit 95% moins cher que Clay ou Apollo.
- **V2** : Support multi-LLM (OpenAI, Anthropic, modèles locaux), interface améliorée avec suivi en temps réel.

---

## Slide 6 — Brique 3 : Twenty CRM — Le CRM open source nouvelle génération
**Heading** : Twenty CRM remplace Salesforce avec 40 000 stars GitHub, une API GraphQL et un modèle de données entièrement personnalisable
**Sous-titre** : twenty.com | YC S23 | Fondateurs français | TypeScript, React, PostgreSQL
**Contenu** :
- **Modèle de données flexible** : Comme Salesforce, tout est un "objet" personnalisable. Créez des champs custom pour le portage (TJM, compétences, statut consultant, société de portage).
- **Vues personnalisables** : Table, Kanban, filtres avancés et favoris pour visualiser le pipeline commercial selon vos besoins.
- **API puissante** : GraphQL et REST pour l'intégration programmatique. Webhooks pour les événements en temps réel.
- **Extension Chrome** : Capture de leads directement depuis LinkedIn ou n'importe quel site web.
- **Synchronisation emails** : Connectez Gmail/Outlook pour centraliser toutes les communications dans le CRM.
- **Connecteur n8n** : Nœud communautaire disponible + MCP Server pour intégration avec assistants IA.
- **Pricing** : Self-hosted gratuit (Docker), Cloud à partir de 18€/mois par utilisateur.

---

## Slide 7 — Brique 4 : n8n — L'orchestrateur qui connecte tout
**Heading** : n8n orchestre les 500+ intégrations avec un éditeur visuel et des agents IA natifs, le tout sous votre contrôle
**Sous-titre** : n8n.io | 176 000+ stars | Fair-code | TypeScript, Node.js
**Contenu** :
- **Éditeur visuel** : Interface drag-and-drop pour créer des workflows complexes sans coder, avec possibilité d'ajouter du code JavaScript/Python pour les cas avancés.
- **500+ intégrations** : LinkedIn, Gmail, Slack, Google Sheets, Notion, HubSpot, et bien sûr Twenty CRM via son nœud dédié.
- **AI Agents natifs** : Créez des agents IA directement dans n8n avec support multi-LLM (OpenAI, Anthropic, Ollama). Idéal pour la qualification automatique et la rédaction de messages.
- **Scénarios clés pour Portage AI** :
  - Workflow 1 : OpenOutreach → Fire-Enrich → Twenty CRM (pipeline complet)
  - Workflow 2 : Nouveau lead Twenty → Email de bienvenue personnalisé → Séquence de nurturing
  - Workflow 3 : Alerte Slack quand un prospect atteint le score 80+ → Assignation automatique à un commercial
  - Workflow 4 : Rapport hebdomadaire automatique des KPIs de prospection
- **Déploiement** : Self-hosted (Docker) gratuit, Cloud à partir de 24€/mois.

---

## Slide 8 — Comparatif coûts : Open Source vs SaaS propriétaire
**Heading** : L'architecture open source réduit les coûts de prospection de 94% par rapport aux solutions SaaS équivalentes
**Tableau comparatif** :

| Fonction | Solution SaaS | Coût/mois | Solution Open Source | Coût/mois |
|---|---|---|---|---|
| Scraping LinkedIn | LinkedIn Sales Nav + Phantombuster | 180€ | OpenOutreach | 0€ (self-hosted) |
| Enrichissement | Clay ou Apollo | 149€ | Fire-Enrich | ~5€ (API LLM) |
| CRM | Salesforce Essentials | 25€/user | Twenty CRM | 0€ (self-hosted) |
| Orchestration | Zapier Pro | 49€ | n8n | 0€ (self-hosted) |
| **Total (5 users)** | | **~1 600€/mois** | | **~95€/mois** |

**Note** : Le coût open source inclut uniquement l'hébergement serveur (~90€/mois pour un VPS) et les appels API LLM (~5€/mois). L'économie annuelle est de **~18 000€**.

---

## Slide 9 — Flux de données : du profil LinkedIn au contrat signé
**Heading** : Le parcours complet d'un prospect traverse 8 étapes automatisées en moins de 72 heures
**Schéma du flux** (vertical, étapes numérotées) :
1. **Recherche** — n8n déclenche OpenOutreach avec les critères cibles (DevOps, Data, Cloud, Freelance, IDF)
2. **Scraping** — OpenOutreach extrait le profil LinkedIn complet via l'API Voyager (nom, poste, entreprise, compétences)
3. **Qualification ML** — Le modèle GPC + BALD attribue un score de 0 à 100 basé sur l'historique de conversion
4. **Enrichissement** — Fire-Enrich complète avec les données entreprise (taille, funding, stack, décideurs)
5. **Injection CRM** — n8n pousse le lead enrichi dans Twenty CRM via l'API GraphQL avec tous les champs mappés
6. **Outreach** — Message LinkedIn personnalisé envoyé automatiquement (template Jinja2 adapté au profil)
7. **Nurturing** — Séquence email automatique pour les leads qualifiés (3 emails sur 2 semaines)
8. **Conversion** — Alerte commerciale + assignation automatique quand le prospect répond ou accepte la connexion

---

## Slide 10 — Plan de déploiement en 4 phases
**Heading** : Un déploiement progressif sur 8 semaines permet de valider chaque brique avant l'intégration complète
**Timeline** :

**Phase 1 — Semaines 1-2 : Fondations**
Déployer Twenty CRM sur un VPS (Docker Compose). Configurer le modèle de données portage (objets Consultant, Mission, Société). Importer les contacts existants. Former l'équipe commerciale.

**Phase 2 — Semaines 3-4 : Orchestration**
Installer n8n et créer les premiers workflows (alertes, rapports automatiques). Connecter n8n à Twenty CRM via le nœud dédié. Mettre en place les webhooks pour les événements clés.

**Phase 3 — Semaines 5-6 : Prospection**
Déployer OpenOutreach avec un compte LinkedIn dédié. Configurer les critères de recherche (profils IT freelance, consultants, managers). Lancer les premières campagnes en mode test (10 connexions/jour).

**Phase 4 — Semaines 7-8 : Enrichissement & Optimisation**
Activer Fire-Enrich pour enrichir automatiquement chaque nouveau lead. Connecter le pipeline complet (OpenOutreach → Fire-Enrich → Twenty CRM). Ajuster les modèles ML et les templates de messages. Mesurer les premiers KPIs.

---

## Slide 11 — KPIs attendus et ROI
**Heading** : L'architecture cible permet de multiplier par 5 le volume de leads qualifiés tout en réduisant le coût d'acquisition de 80%
**Métriques projetées** (comparaison Avant / Après) :

| Métrique | Avant (manuel) | Après (automatisé) | Gain |
|---|---|---|---|
| Profils identifiés / semaine | 50 | 500 | x10 |
| Leads qualifiés / semaine | 10 | 80 | x8 |
| Coût par lead qualifié | 45€ | 8€ | -82% |
| Temps commercial sur prospection | 68% | 15% | -53 pts |
| Temps moyen découverte → RDV | 3 semaines | 4 jours | -85% |
| Taux de réponse LinkedIn | 8% | 22% | +14 pts |

**ROI estimé** : Avec un panier moyen de 2 000€/mois par consultant porté et un taux de conversion de 4,3%, chaque tranche de 100 leads qualifiés génère ~8 600€ de revenus mensuels récurrents.

---

## Slide 12 — Conclusion et prochaines étapes
**Heading** : L'architecture OpenOutreach + Fire-Enrich + Twenty CRM + n8n donne à Portage AI un avantage compétitif décisif
**Points clés** :
- **Souveraineté des données** : Toutes les données restent sur vos serveurs, conformité RGPD native, aucune dépendance à un fournisseur SaaS.
- **Économie massive** : ~18 000€/an d'économie par rapport aux solutions propriétaires équivalentes.
- **Scalabilité** : L'architecture modulaire permet d'ajouter de nouvelles sources (Indeed, Google Maps, annuaires) sans refonte.
- **Intelligence artificielle** : Le ML d'OpenOutreach et les agents IA de Fire-Enrich s'améliorent continuellement avec les données accumulées.

**Prochaines étapes** :
1. Validation de l'architecture par l'équipe technique (cette semaine)
2. Provisionnement du serveur et déploiement de Twenty CRM (semaine prochaine)
3. Lancement du POC sur 50 profils cibles (semaine 3)
4. Revue des résultats et décision de mise en production (semaine 5)
