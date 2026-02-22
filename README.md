# Portage AI — Sales Force Command Center

Plateforme SaaS de pilotage commercial pour le portage salarial, propulsée par l'intelligence artificielle.

## Livrables

### 1. Site Web SaaS (`index.html`)
Site internet complet et autonome, prêt à être hébergé sur n'importe quel serveur web (Netlify, Vercel, OVH, etc.).

**Fonctionnalités :**
- Dashboard avec KPIs en temps réel
- 5 Agents IA (ARIA, MAX, NOAH, LUNA, ALEX)
- Pipeline B2B et B2C
- CRM intégré
- Simulateur de portage salarial
- Gestion des campagnes
- Module LinkedIn
- Gestion des missions
- Configuration système
- Sidebar navigable avec 10 sections

### 2. Spécifications Techniques Simulateur → CRM (`specifications-simulateur-crm.md`)
Document détaillant l'intégration complète :
- Flux en 7 étapes
- Schéma de données des fiches prospects (15 champs)
- Algorithme de calcul Light Portage
- Scoring automatique
- Rotation d'affectation des agents IA (LUNA → ALEX → ARIA)
- Injection pipeline B2C
- Notifications
- Schéma SQL cible pour la production
- 8 endpoints API recommandés

### 3. Rapport d'Audit (`audit-rapport.md`)
Rapport d'audit du simulateur de portage commercial existant.

## Déploiement

Le site est un fichier HTML autonome. Pour le déployer :

```bash
# Serveur local
python3 -m http.server 8080

# Ou déposez index.html sur Netlify, Vercel, GitHub Pages, OVH, etc.
```

## Technologies

- HTML5 / CSS3 / JavaScript (vanilla)
- Chart.js pour les graphiques
- Google Fonts (Inter, Material Icons)
- Design responsive avec sidebar collapsible

## Auteur

Projet développé pour **Portage AI** — Sales Force Command Center.
