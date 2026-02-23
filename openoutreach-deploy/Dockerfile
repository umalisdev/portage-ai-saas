# ─────────────────────────────────────────────────────────────────────
# Dockerfile — OpenOutreach + Intégration Dashboard Portage AI
# Image custom avec toutes les dépendances pré-installées
# ─────────────────────────────────────────────────────────────────────
FROM python:3.12-slim

# Métadonnées
LABEL maintainer="Portage AI <contact@light-portage.fr>"
LABEL description="OpenOutreach LinkedIn Scraper + Dashboard Integration"
LABEL version="1.0.0"

# Variables d'environnement
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive \
    DJANGO_SETTINGS_MODULE=linkedin.django_settings

# Dépendances système (Playwright, xvfb, outils)
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    xauth \
    dbus-x11 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 \
    libxshmfence1 \
    fonts-liberation \
    fonts-noto-color-emoji \
    git \
    curl \
    jq \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Répertoire de travail
WORKDIR /app

# Cloner OpenOutreach
RUN git clone --depth 1 https://github.com/eracle/OpenOutreach.git /app

# Installer les dépendances Python
RUN pip install --no-cache-dir -r requirements/common.txt && \
    pip install --no-cache-dir -r requirements/crm.txt && \
    pip install --no-cache-dir -r requirements/analytics.txt 2>/dev/null || true

# Installer Playwright et les navigateurs
RUN pip install --no-cache-dir playwright && \
    playwright install chromium && \
    playwright install-deps chromium

# Copier les fichiers de configuration Portage AI
COPY export_to_dashboard.py /app/export_to_dashboard.py
COPY init_portage_ai.py /app/init_portage_ai.py
COPY entrypoint.sh /app/entrypoint.sh

# Rendre les scripts exécutables
RUN chmod +x /app/entrypoint.sh

# Créer les répertoires nécessaires
RUN mkdir -p /app/assets/cookies /app/assets/db /dashboard

# Accepter la notice légale par défaut
RUN touch /app/assets/cookies/.legal_notice_accepted

# Volumes pour la persistance
VOLUME ["/app/assets", "/dashboard"]

# Ports exposés
EXPOSE 8000 5900

# Point d'entrée
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["daemon"]
