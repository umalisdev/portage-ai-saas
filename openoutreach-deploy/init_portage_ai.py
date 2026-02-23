#!/usr/bin/env python3
"""
init_portage_ai.py — Initialisation automatique pour Portage AI
Configure la campagne, le profil LinkedIn et les mots-clés de recherche.
"""
import os
import sys

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "linkedin.django_settings")

import django
django.setup()

from django.contrib.auth.models import User
from linkedin.models import Campaign, LinkedInProfile, SearchKeyword
from common.models import Department


def main():
    # ─── 1. Créer le département et la campagne ──────────────────────
    dept_name = os.environ.get("CAMPAIGN_NAME", "Portage AI Prospection")
    dept, _ = Department.objects.get_or_create(name=dept_name)

    campaign, created = Campaign.objects.get_or_create(
        department=dept,
        defaults={
            "product_docs": (
                "Portage AI est une plateforme SaaS de portage salarial augmentée par l'IA. "
                "Elle offre aux consultants IT freelances une solution complète : "
                "simulation de revenus, optimisation fiscale, CRM de prospection, "
                "agents IA commerciaux (ARIA, LUNA, NOAH, ALEX, MAX), "
                "et un dashboard de pilotage en temps réel. "
                "Notre proposition de valeur : transformer chaque freelance en entrepreneur "
                "avec la sécurité du salariat et la puissance de l'IA."
            ),
            "campaign_objective": (
                "Identifier et recruter des consultants IT freelances en France "
                "qui pourraient bénéficier du portage salarial. "
                "Cibles prioritaires : DevOps, Cloud, Data, IA/ML, SAP, "
                "chefs de projet IT, développeurs seniors. "
                "TJM cible : 400-1200€/jour. "
                "Zones : Paris, Lyon, Nantes, Bordeaux, Toulouse, Marseille, Lille."
            ),
            "booking_link": os.environ.get("BOOKING_LINK", ""),
        },
    )

    if created:
        print(f"✅ Campagne créée : {dept_name}")
    else:
        print(f"ℹ️  Campagne existante : {dept_name}")

    # ─── 2. Configurer le pipeline CRM ────────────────────────────────
    from linkedin.management.setup_crm import ensure_campaign_pipeline
    ensure_campaign_pipeline(dept)
    print("✅ Pipeline CRM configuré")

    # ─── 3. Créer le profil LinkedIn ──────────────────────────────────
    linkedin_username = os.environ.get("LINKEDIN_USERNAME", "")
    linkedin_password = os.environ.get("LINKEDIN_PASSWORD", "")

    if not linkedin_username or not linkedin_password:
        print("⚠️  LINKEDIN_USERNAME ou LINKEDIN_PASSWORD non défini, profil non créé")
    else:
        handle = linkedin_username.split("@")[0].lower().replace(".", "_").replace("+", "_")

        user, user_created = User.objects.get_or_create(
            username=handle,
            defaults={"is_staff": True, "is_active": True},
        )
        if user_created:
            user.set_unusable_password()
            user.save()

        # Ajouter l'utilisateur au groupe du département
        if dept not in user.groups.all():
            user.groups.add(dept)

        profile, prof_created = LinkedInProfile.objects.get_or_create(
            user=user,
            defaults={
                "linkedin_username": linkedin_username,
                "linkedin_password": linkedin_password,
                "subscribe_newsletter": False,
                "connect_daily_limit": int(os.environ.get("CONNECT_DAILY_LIMIT", "20")),
                "connect_weekly_limit": int(os.environ.get("CONNECT_WEEKLY_LIMIT", "100")),
                "follow_up_daily_limit": int(os.environ.get("FOLLOWUP_DAILY_LIMIT", "30")),
            },
        )

        if prof_created:
            print(f"✅ Profil LinkedIn créé : {linkedin_username} (handle: {handle})")
        else:
            print(f"ℹ️  Profil LinkedIn existant : {linkedin_username}")

    # ─── 4. Configurer les mots-clés de recherche ─────────────────────
    default_keywords = [
        "consultant freelance portage salarial France",
        "freelance DevOps Paris",
        "consultant SAP France",
        "ingénieur data freelance",
        "chef de projet IT freelance France",
        "consultant cloud AWS Azure France",
        "développeur senior freelance Paris",
        "consultant IA machine learning France",
        "freelance cybersécurité France",
        "architecte solution cloud freelance",
        "consultant ERP freelance France",
        "scrum master freelance Paris",
    ]

    # Permettre des mots-clés personnalisés via variable d'environnement
    custom_keywords = os.environ.get("SEARCH_KEYWORDS", "")
    if custom_keywords:
        keywords = [kw.strip() for kw in custom_keywords.split(";") if kw.strip()]
    else:
        keywords = default_keywords

    created_count = 0
    for kw in keywords:
        _, created = SearchKeyword.objects.get_or_create(
            campaign=campaign,
            keyword=kw,
        )
        if created:
            created_count += 1

    total = SearchKeyword.objects.filter(campaign=campaign).count()
    print(f"✅ Mots-clés de recherche : {created_count} créés, {total} au total")

    # ─── Résumé ───────────────────────────────────────────────────────
    print()
    print("━" * 60)
    print("  Configuration Portage AI terminée")
    print("━" * 60)
    print(f"  Campagne    : {dept_name}")
    print(f"  Profil      : {linkedin_username or 'Non configuré'}")
    print(f"  Mots-clés   : {total}")
    print(f"  Limites     : {os.environ.get('CONNECT_DAILY_LIMIT', '20')}/jour, "
          f"{os.environ.get('CONNECT_WEEKLY_LIMIT', '100')}/sem")
    print("━" * 60)


if __name__ == "__main__":
    main()
