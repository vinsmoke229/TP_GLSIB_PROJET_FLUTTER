# 🎫 EventMaster — Plateforme de Billetterie Intelligente

**EventMaster** est une solution complète de **gestion d’événements et de vente de billets**, conçue pour offrir une expérience fluide aussi bien aux utilisateurs qu’aux administrateurs.

Le projet repose sur :

* 📱 une application mobile moderne pour les clients,
* 💻 un backoffice web puissant pour les organisateurs,
* ⚙️ un backend sécurisé et scalable.

---

## 🚀 Fonctionnalités Principales

### 📱 Application Mobile (Flutter)

* 🔐 **Authentification complète**

  * Inscription, connexion
  * Gestion de session via JWT

* 🎯 **Parcours de personnalisation**

  * Sélection des centres d’intérêt
  * Localisation à la première connexion

* 💰 **Wallet (Fintech)**

  * Portefeuille virtuel rechargeable
  * Paiement rapide des billets en un clic

* 🎟️ **Billetterie intelligente**

  * Génération de billets numériques
  * QR Code unique pour le contrôle d’accès

* 🗺️ **Navigation GPS**

  * Itinéraire vers les lieux d’événements
  * Intégration Google Maps

* 🤖 **Assistant IA**

  * Recommandation d’événements personnalisés
  * Basée sur les goûts et l’historique utilisateur

---

### 💻 Backoffice & Administration (React + Django)

* 🗓️ **Gestion des événements**

  * Création / modification d’événements
  * Gestion multi-sessions (plusieurs dates et horaires)

* 🎫 **Gestion des tickets & stocks**

  * Types de billets : Standard, VIP, VVIP
  * Suivi des places disponibles en temps réel

* 📊 **Suivi des ventes**

  * Tableau de bord dynamique
  * Statistiques financières et volume de ventes

* 🔒 **Sécurité & intégrité**

  * Transactions atomiques
  * Protection des soldes et des stocks

---

## 🛠 Stack Technique

### Backend

* Django 5.x
* Django REST Framework (DRF)

### Base de données

* PostgreSQL (production)
* SQLite (développement)

### Mobile

* Flutter 3.x
* Architecture BLoC / Cubit

### Web Admin

* React
* TypeScript
* Tailwind CSS

### Intelligence Artificielle

* API Google Gemini (recommandations intelligentes)

### DevOps

* Docker
* Docker Compose

---

## ⚙️ Installation & Lancement

### 1️⃣ Backend (Django)

```bash
cd backend
python -m venv venv
source venv/bin/activate   # venv\Scripts\activate sur Windows
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

---

### 2️⃣ Application Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

---

### 3️⃣ Web Admin (React)

```bash
cd web
npm install
npm run dev
```

---

## 🗺️ Contrat d’Intégration (⚠️ IMPORTANT)

⚠️ **Pour garantir la compatibilité entre le Web et le Mobile**, les administrateurs **doivent obligatoirement renseigner les champs suivants** lors de la création d’un événement :

* 🏷️ **Catégorie**

  * `Music`, `Tech`, `Art`, `Sport`, `Food`, `Tourism`

* 📍 **Coordonnées GPS**

  * Latitude
  * Longitude
    👉 nécessaires pour la navigation mobile

* 🗓️ **Sessions**

  * Au moins **une date et une heure**
  * Chaque événement doit avoir ≥ 1 session

* 💱 **Devise**

  * Tous les prix doivent être saisis en **FCFA**

❌ Le non-respect de ces règles peut provoquer des erreurs côté mobile.

---

## 📌 Objectifs du Projet

* Centraliser la gestion d’événements
* Simplifier l’achat de billets
* Offrir une expérience utilisateur moderne et sécurisée
* Fournir aux organisateurs des outils de suivi performants

---

## 📄 Licence

Projet académique / démonstratif — libre d’utilisation à des fins pédagogiques.

---

