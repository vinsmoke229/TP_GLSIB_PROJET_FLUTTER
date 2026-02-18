🎫 EventMaster - Solution de Billetterie Élite
EventMaster est une plateforme complète de gestion d'événements et de vente de billets. Le projet combine une application mobile pour les clients, un tableau de bord web pour les administrateurs, le tout propulsé par un backend robuste en Django.
🚀 Fonctionnalités Principales
📱 Application Mobile (Flutter)
Authentification complète : Inscription, connexion et persistance de session (JWT).
Parcours de personnalisation : Configuration des intérêts et de la localisation à la première connexion.
Système de Wallet (Fintech) : Portefeuille virtuel rechargeable pour acheter des billets en un clic.
Billetterie Intelligente : Génération de billets avec QR Code unique pour le contrôle d'accès.
Navigation GPS : Intégration Google Maps pour tracer l'itinéraire vers les lieux d'événements.
Assistant IA : Recommandations d'événements personnalisées basées sur les goûts de l'utilisateur.
💻 Backoffice & Admin (React & Django)
Gestion des Événements : Création et modification d'événements avec gestion multi-sessions (horaires multiples).
Gestion des Stocks : Contrôle des types de tickets (Standard, VIP, VVIP) et des places disponibles.
Suivi des Ventes : Tableau de bord en temps réel avec statistiques financières.
Sécurité : Transactions atomiques pour garantir l'intégrité des soldes et des stocks.
🛠 Stack Technique
Backend : Django 5.x, Django REST Framework (DRF)
Base de données : PostgreSQL (Production) / SQLite (Développement)
Mobile : Flutter 3.x (Architecture BLoC)
Web Admin : React, TypeScript, Tailwind CSS
IA : Intégration API Google Gemini
Conteneurisation : Docker & Docker Compose
⚙️ Installation et Lancement
1. Backend (Django)
code
Bash
cd backend
python -m venv venv
source venv/bin/activate  # venv\Scripts\activate sur Windows
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
2. Mobile (Flutter)
code
Bash
cd mobile
flutter pub get
flutter run
3. Web Admin (React)
code
Bash
cd web
npm install
npm run dev
🗺️ Contrat d'Intégration (Important)
Pour assurer la compatibilité entre le Web et le Mobile, les administrateurs doivent impérativement remplir les champs suivants lors de la création d'un événement :
Catégorie : Music, Tech, Art, Sport, Food ou Tourism.
Coordonnées : Latitude et Longitude pour le GPS mobile.
Sessions : Au moins une date et une heure rattachées.
Devise : Les prix doivent être saisis en FCFA.
