#!/usr/bin/env python3
"""
export_to_dashboard.py — Script d'intégration OpenOutreach → Dashboard Portage AI

Ce script extrait les profils (Leads + Contacts) du CRM OpenOutreach
et génère un fichier JavaScript injectable dans le dashboard Portage AI.

Usage:
    python export_to_dashboard.py                          # Export vers stdout
    python export_to_dashboard.py --output profiles.js     # Export vers fichier
    python export_to_dashboard.py --inject /path/to/dashboard.html  # Injection directe

Prérequis:
    - OpenOutreach installé et configuré (migrations + setup_crm)
    - DJANGO_SETTINGS_MODULE=linkedin.django_settings
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "linkedin.django_settings")

import django
django.setup()

from crm.models import Lead, Contact, Deal, Stage
from linkedin.navigation.enums import ProfileState


# ─── Mapping des statuts CRM → statuts dashboard ────────────────────────
STAGE_MAP = {
    "New": "Nouveau",
    "Pending": "En attente",
    "Connected": "Connecté",
    "Completed": "Converti",
    "Failed": "Disqualifié",
}

STATUS_COLORS = {
    "Nouveau": "#00d4aa",
    "En attente": "#ffa726",
    "Contacté": "#42a5f5",
    "Intéressé": "#66bb6a",
    "Connecté": "#42a5f5",
    "Converti": "#ab47bc",
    "Disqualifié": "#ef5350",
    "RDV planifié": "#ffa726",
}

# ─── Agents IA rotatifs ─────────────────────────────────────────────────
AGENTS = ["ARIA", "LUNA", "NOAH", "ALEX", "MAX"]
AGENT_ICONS = {
    "ARIA": "🔍",
    "LUNA": "✨",
    "NOAH": "🎯",
    "ALEX": "🎯",
    "MAX": "📊",
}


def extract_linkedin_url(lead):
    """Extrait l'URL LinkedIn depuis le champ website ou description du Lead."""
    if lead.website and "linkedin.com" in str(lead.website):
        return str(lead.website)
    if lead.description:
        match = re.search(r'https?://(?:www\.)?linkedin\.com/in/[^\s"\'<>]+', lead.description)
        if match:
            return match.group(0)
    return ""


def extract_skills(lead):
    """Extrait les compétences depuis les tags ou la description."""
    skills = []
    # Depuis les tags CRM
    if hasattr(lead, 'tags'):
        for tag in lead.tags.all():
            skills.append(str(tag))
    # Depuis la description (recherche de mots-clés techniques)
    if lead.description:
        tech_keywords = [
            "Python", "Java", "JavaScript", "TypeScript", "React", "Angular", "Vue",
            "Node.js", "Django", "Flask", "AWS", "Azure", "GCP", "Docker", "Kubernetes",
            "SAP", "S/4HANA", "ABAP", "Fiori", "DevOps", "CI/CD", "Terraform",
            "Power BI", "Tableau", "SQL", "NoSQL", "MongoDB", "PostgreSQL",
            "Machine Learning", "Deep Learning", "NLP", "PyTorch", "TensorFlow",
            "Agile", "Scrum", "JIRA", "PMO", "Prince2", "PMP",
            "Figma", "Sketch", "UX", "UI", "Design System",
            "Salesforce", "ServiceNow", "Oracle", "Workday",
            "Cybersécurité", "RGPD", "ISO 27001",
            "MLOps", "DataOps", "Microservices", "API REST", "GraphQL",
        ]
        desc_lower = lead.description.lower()
        for kw in tech_keywords:
            if kw.lower() in desc_lower and kw not in skills:
                skills.append(kw)
    return skills[:5] if skills else ["Non renseigné"]


def extract_tjm(lead):
    """Extrait le TJM depuis la description ou retourne une valeur par défaut."""
    if lead.description:
        match = re.search(r'(\d{3,4})\s*€?\s*/?\s*j(?:our)?', lead.description)
        if match:
            return int(match.group(1))
    return 0


def compute_score(lead, deal=None):
    """Calcule un score de 0-100 basé sur la complétude du profil et le statut."""
    score = 50  # Base
    if lead.first_name and lead.last_name:
        score += 5
    if lead.email:
        score += 10
    if lead.phone or lead.mobile:
        score += 5
    if lead.description and len(lead.description) > 50:
        score += 10
    if lead.company_name:
        score += 5
    if lead.city_name:
        score += 5
    if extract_linkedin_url(lead):
        score += 5
    if extract_skills(lead) != ["Non renseigné"]:
        score += 5
    # Bonus selon le statut du deal
    if deal:
        stage_name = deal.stage.name if deal.stage else ""
        if stage_name == "Connected":
            score += 5
        elif stage_name == "Completed":
            score += 10
    return min(score, 100)


def get_status(lead, deal=None):
    """Détermine le statut du profil pour le dashboard."""
    if lead.disqualified:
        return "Disqualifié"
    if deal and deal.stage:
        return STAGE_MAP.get(deal.stage.name, "Nouveau")
    if lead.contact:
        return "Intéressé"
    if lead.description:
        return "Contacté"
    return "Nouveau"


def lead_to_profile(lead, index):
    """Convertit un Lead CRM en profil dashboard."""
    deal = Deal.objects.filter(lead=lead).first()
    status = get_status(lead, deal)
    score = compute_score(lead, deal)
    agent = AGENTS[index % len(AGENTS)]
    skills = extract_skills(lead)
    tjm = extract_tjm(lead)
    linkedin_url = extract_linkedin_url(lead)

    # Tags métier pour la recherche
    tags = ["informatique", "IT", "consultant", "freelance"]
    if lead.title:
        title_lower = lead.title.lower()
        if any(w in title_lower for w in ["dev", "développ", "engineer", "ingénieur"]):
            tags.extend(["développement", "engineering"])
        if any(w in title_lower for w in ["data", "analyst", "scientist"]):
            tags.extend(["data", "data science", "analytics"])
        if any(w in title_lower for w in ["cloud", "devops", "infra", "sre"]):
            tags.extend(["cloud", "infrastructure", "devops"])
        if any(w in title_lower for w in ["sap", "erp", "abap"]):
            tags.extend(["SAP", "ERP"])
        if any(w in title_lower for w in ["chef de projet", "project", "pmo", "scrum"]):
            tags.extend(["gestion de projet", "management"])
        if any(w in title_lower for w in ["ux", "ui", "design"]):
            tags.extend(["design", "UX/UI"])
        if any(w in title_lower for w in ["ia", "ai", "machine", "ml", "deep"]):
            tags.extend(["intelligence artificielle", "IA", "machine learning"])

    profile = {
        "name": f"{lead.first_name or ''} {lead.last_name or ''}".strip() or "Inconnu",
        "title": lead.title or "Non renseigné",
        "company": lead.company_name or "Freelance",
        "location": lead.city_name or "France",
        "score": score,
        "skills": skills,
        "status": status,
        "statusColor": STATUS_COLORS.get(status, "#00d4aa"),
        "tjm": f"{tjm}€/j" if tjm > 0 else "Non renseigné",
        "tjmValue": tjm,
        "agent": agent,
        "agentIcon": AGENT_ICONS[agent],
        "linkedinUrl": linkedin_url,
        "email": lead.email or "",
        "phone": lead.phone or lead.mobile or "",
        "bio": (lead.description or "")[:300],
        "tags": list(set(tags)),
        "experience": [],
        "formation": "",
        "disponibilite": "À confirmer",
        "secteurs": [],
    }
    return profile


def export_profiles():
    """Exporte tous les profils (Leads) du CRM."""
    leads = Lead.objects.select_related(
        'contact', 'company', 'department', 'lead_source'
    ).prefetch_related('tags').order_by('-creation_date')

    profiles = []
    for i, lead in enumerate(leads):
        profiles.append(lead_to_profile(lead, i))

    return profiles


def generate_js(profiles):
    """Génère le code JavaScript pour le dashboard."""
    js_profiles = json.dumps(profiles, ensure_ascii=False, indent=2)
    return f"""// Profils LinkedIn importés depuis OpenOutreach
// Généré le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
// Nombre de profils: {len(profiles)}

const LINKEDIN_PROFILES = {js_profiles};
"""


def inject_into_dashboard(profiles, dashboard_path):
    """Injecte les profils directement dans le fichier dashboard.html."""
    with open(dashboard_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Trouver et remplacer le tableau LINKEDIN_PROFILES
    js_array = json.dumps(profiles, ensure_ascii=False, indent=2)

    # Pattern: const LINKEDIN_PROFILES = [...];
    pattern = r'const LINKEDIN_PROFILES = \[[\s\S]*?\];'
    replacement = f'const LINKEDIN_PROFILES = {js_array};'

    new_content, count = re.subn(pattern, replacement, content, count=1)

    if count == 0:
        print("ERREUR: Impossible de trouver 'const LINKEDIN_PROFILES = [...]' dans le dashboard.")
        print("Assurez-vous que le fichier dashboard.html contient cette variable.")
        sys.exit(1)

    with open(dashboard_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"✅ {len(profiles)} profils injectés dans {dashboard_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Exporte les profils OpenOutreach vers le dashboard Portage AI"
    )
    parser.add_argument(
        "--output", "-o",
        help="Chemin du fichier JavaScript de sortie (défaut: stdout)"
    )
    parser.add_argument(
        "--inject", "-i",
        help="Chemin du fichier dashboard.html pour injection directe"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Exporter en format JSON brut au lieu de JavaScript"
    )
    args = parser.parse_args()

    profiles = export_profiles()
    print(f"📊 {len(profiles)} profils extraits du CRM OpenOutreach", file=sys.stderr)

    if args.inject:
        inject_into_dashboard(profiles, args.inject)
    elif args.json:
        output = json.dumps(profiles, ensure_ascii=False, indent=2)
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(output)
            print(f"✅ Export JSON sauvegardé dans {args.output}", file=sys.stderr)
        else:
            print(output)
    else:
        js_code = generate_js(profiles)
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(js_code)
            print(f"✅ Export JS sauvegardé dans {args.output}", file=sys.stderr)
        else:
            print(js_code)


if __name__ == "__main__":
    main()
