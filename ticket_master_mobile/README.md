# 🎫 EventMaster Mobile

> Application mobile de billetterie événementielle de nouvelle génération avec système de Wallet intégré, QR Codes dynamiques et recommandations par IA.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📋 Table des Matières

- [Présentation](#-présentation)
- [Stack Technique](#-stack-technique)
- [Prérequis](#-prérequis)
- [Installation Rapide](#-installation-rapide)
- [Configuration de l'API](#-configuration-de-lapi)
- [Fonctionnalités Clés](#-fonctionnalités-clés)
- [Architecture du Projet](#-architecture-du-projet)
- [Captures d'Écran](#-captures-décran)
- [Crédits](#-crédits)
- [Licence](#-licence)

---

## 🎯 Présentation

**EventMaster Mobile** est une application Flutter de billetterie événementielle professionnelle qui offre une expérience utilisateur fluide et moderne. L'application se connecte à un backend Django REST API avec PostgreSQL pour gérer les événements, les achats de billets, et les transactions financières en temps réel.

### Points Forts

✨ **Interface Élégante** - Design moderne avec thème Emerald Green (#10B981)  
🔐 **Sécurité Renforcée** - Authentification JWT avec stockage sécurisé  
💰 **Wallet Intégré** - Système de portefeuille électronique avec recharge instantanée  
📱 **QR Codes Dynamiques** - Génération de billets avec codes QR uniques  
🗺️ **GPS & Itinéraires** - Intégration Google Maps pour localiser les événements  
🤖 **IA Recommandations** - Suggestions personnalisées d'événements  
🎨 **UX Optimisée** - Navigation fluide avec 6 onglets et animations

---

## 🛠️ Stack Technique

### Frontend
- **Flutter SDK** `>=3.0.0` - Framework cross-platform
- **Dart** `>=3.0.0` - Langage de programmation

### Architecture & State Management
- **BLoC Pattern** (`flutter_bloc ^8.1.6`) - Gestion d'état réactive
- **Provider** (`^6.1.2`) - Injection de dépendances

### Networking & Storage
- **Dio** (`^5.4.0`) - Client HTTP avec intercepteurs JWT
- **FlutterSecureStorage** (`^9.0.0`) - Stockage sécurisé des tokens
- **SharedPreferences** (`^2.2.3`) - Persistance locale

### UI & Utilities
- **Google Fonts** (`^6.2.1`) - Typographie personnalisée
- **QR Flutter** (`^4.1.0`) - Génération de QR Codes
- **Geolocator** (`^13.0.0`) - Services de géolocalisation
- **Intl** (`^0.19.0`) - Formatage des devises (FCFA)
- **CachedNetworkImage** (`^3.3.0`) - Mise en cache des images

---

## ✅ Prérequis

Avant de commencer, assurez-vous d'avoir installé :

1. **Flutter SDK** (version 3.0 ou supérieure)
   ```bash
   flutter --version
   ```

2. **Un émulateur ou appareil physique**
   - Android Studio (émulateur Android)
   - Xcode (simulateur iOS - macOS uniquement)
   - Appareil Android/iOS en mode développeur

3. **Backend Django** (doit être en cours d'exécution)
   - URL par défaut : `http://10.0.2.2:8000` (émulateur Android)
   - URL Web : `http://localhost:8000` (navigateur)

---

## 🚀 Installation Rapide

### 1. Cloner le Dépôt

```bash
git clone https://github.com/votre-organisation/event_app.git
cd event_app
```

### 2. Installer les Dépendances

```bash
flutter pub get
```

### 3. Vérifier la Configuration

```bash
flutter doctor
```

Résolvez tous les problèmes signalés par Flutter Doctor avant de continuer.

### 4. Lancer l'Application

```bash
# Sur émulateur/appareil connecté
flutter run

# Sur un appareil spécifique
flutter devices
flutter run -d <device_id>

# En mode release (optimisé)
flutter run --release
```

---

## ⚙️ Configuration de l'API

### 🔴 CRITIQUE : Configurer l'URL du Backend

L'application doit se connecter à votre backend Django. L'URL varie selon la plateforme :

| Plateforme | URL Backend | Fichier à Modifier |
|------------|-------------|-------------------|
| **Émulateur Android** | `http://10.0.2.2:8000/api` | `lib/services/dio_client.dart` |
| **Simulateur iOS** | `http://localhost:8000/api` | `lib/services/dio_client.dart` |
| **Appareil Physique** | `http://<IP_MACHINE>:8000/api` | `lib/services/dio_client.dart` |
| **Web** | `http://localhost:8000/api` | `lib/services/dio_client.dart` |

### Étapes de Configuration

#### Option 1 : Modifier `dio_client.dart` (Recommandé)

Ouvrez `lib/services/dio_client.dart` et modifiez la méthode `_baseUrl` :

```dart
static String get _baseUrl {
  final url = kIsWeb 
      ? 'http://localhost:8000/api'        // Web
      : 'http://10.0.2.2:8000/api';        // Android Emulator
  return url.trim();
}
```

**Pour un appareil physique**, remplacez par l'IP de votre machine :

```dart
static String get _baseUrl {
  return 'http://192.168.1.100:8000/api';  // Remplacez par votre IP
}
```

#### Option 2 : Variable d'Environnement (Avancé)

Créez un fichier `.env` à la racine :

```env
API_BASE_URL=http://10.0.2.2:8000/api
```

### 🔍 Trouver l'IP de Votre Machine

**Windows :**
```cmd
ipconfig
```

**macOS/Linux :**
```bash
ifconfig | grep "inet "
```

### ✅ Vérifier la Connexion

1. Assurez-vous que Django est en cours d'exécution :
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

2. Testez l'API depuis votre navigateur :
   ```
   http://localhost:8000/api/evenements/
   ```

3. Lancez l'application Flutter et vérifiez les logs :
   ```bash
   flutter run
   ```

Vous devriez voir dans la console :
```
🌐 [DioClient] Base URL: http://10.0.2.2:8000/api
✅ [ApiService] Fetched X events
```

---

## 🎨 Fonctionnalités Clés

### 🔐 Authentification JWT

- **Inscription** : Création de compte avec validation des champs
- **Connexion** : Login universel avec sanitization des entrées
- **Sécurité** : Tokens JWT stockés dans FlutterSecureStorage
- **Auto-logout** : Déconnexion automatique sur token expiré (401)

```dart
// Exemple d'utilisation
final authCubit = context.read<AuthCubit>();
await authCubit.login('john@test.com', 'password123');
```

### 🎭 Tunnel de Personnalisation (Setup Flow)

Après l'inscription, l'utilisateur passe par un tunnel de personnalisation :
- Sélection des préférences d'événements
- Configuration du profil
- Activation des notifications

### 🔍 Recherche d'Événements en Temps Réel

- **Recherche Dynamique** : Résultats instantanés depuis PostgreSQL
- **Filtres** : Par catégorie, date, prix, localisation
- **Tri** : Popularité, date, prix croissant/décroissant

### 💳 Système de Wallet

#### Recharge de Portefeuille
```dart
final bookingCubit = context.read<BookingCubit>();
await bookingCubit.rechargeWallet(50000); // +50 000 FCFA
```

#### Achat de Billets
- Sélection dynamique des types de tickets (VIP, Standard, etc.)
- Calendrier interactif pour choisir date et heure
- Validation du solde en temps réel
- Transaction PostgreSQL sécurisée

```dart
await bookingCubit.purchaseTicket(
  idTicket: 1,
  quantite: 2,
  idSession: 5,
);
```

### 🎫 Affichage de Billets avec QR Codes

- **QR Codes Réels** : Format `TICKET-{id_achat}` depuis PostgreSQL
- **Détails Complets** : Événement, date, heure, siège, prix
- **Partage** : Export et partage des billets
- **Historique** : Liste de tous les achats passés

### 🗺️ GPS & Itinéraires Google Maps

- **Localisation** : Affichage de l'adresse de l'événement
- **Itinéraire** : Bouton "Get Directions" ouvrant Google Maps
- **Distance** : Calcul de la distance depuis la position actuelle

```dart
// Ouvre Google Maps avec l'itinéraire
await MapService.openGoogleMaps(
  latitude: event.latitude,
  longitude: event.longitude,
);
```

### 🤖 Recommandations par IA

- **Personnalisées** : Basées sur l'historique et les préférences
- **Bottom Sheet** : Interface élégante avec animation
- **Navigation Directe** : Accès rapide à l'événement recommandé

---

## 📁 Architecture du Projet

```
lib/
├── app/
│   ├── configs/
│   │   ├── colors.dart          # Palette de couleurs (Emerald Green)
│   │   └── theme.dart           # Thème global de l'application
│   └── resources/
│       └── constant/
│           └── named_routes.dart # Routes nommées
│
├── bloc/                         # State Management (BLoC Pattern)
│   ├── auth_cubit.dart          # Gestion de l'authentification
│   ├── auth_state.dart
│   ├── booking_cubit.dart       # Gestion des achats et wallet
│   ├── booking_state.dart
│   ├── event_cubit.dart         # Gestion des événements
│   └── event_state.dart
│
├── data/                         # Modèles de Données
│   ├── user_model.dart          # Utilisateur (id, email, solde)
│   ├── event_model.dart         # Événement (titre, date, lieu)
│   ├── ticket_model.dart        # Ticket (type, prix)
│   ├── session_model.dart       # Session (date, heure)
│   ├── achat_model.dart         # Achat (id, quantité, QR)
│   ├── booking_model.dart       # Réservation
│   └── ai_recommendation_model.dart
│
├── services/                     # Services Backend
│   ├── api_service.dart         # Appels API Django REST
│   ├── dio_client.dart          # Configuration Dio + JWT
│   ├── location_service.dart    # Géolocalisation
│   ├── map_service.dart         # Google Maps
│   └── seed_data_service.dart   # Données de test
│
├── ui/
│   ├── pages/                   # Écrans de l'Application
│   │   ├── splash_screen.dart
│   │   ├── onboarding_page.dart
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── setup_flow_page.dart
│   │   ├── main_screen.dart     # Navigation 6 onglets
│   │   ├── home_page.dart
│   │   ├── explore_page.dart
│   │   ├── discovery_page.dart  # Swipe cards
│   │   ├── favorites_page.dart
│   │   ├── tickets_list_page.dart
│   │   ├── ticket_detail_page.dart
│   │   ├── detail_page.dart     # Détail événement + achat
│   │   ├── profile_page.dart
│   │   └── transaction_history_page.dart
│   │
│   └── widgets/                 # Composants Réutilisables
│       ├── app_logo.dart
│       ├── card_event_this_month.dart
│       ├── card_popular_event.dart
│       ├── ticket_card.dart
│       ├── custom_app_bar.dart
│       └── custom_clipper_ticket.dart
│
└── main.dart                    # Point d'entrée de l'application
```

### Flux de Données (BLoC Pattern)

```
UI (Widget)
    ↓
  Event
    ↓
  Cubit
    ↓
API Service
    ↓
Django Backend
    ↓
PostgreSQL
    ↓
  State
    ↓
UI (Rebuild)
```

---

## 📸 Captures d'Écran

> Ajoutez ici des captures d'écran de votre application

---

## 🧪 Tests

### Lancer les Tests Unitaires

```bash
flutter test
```

### Lancer les Tests d'Intégration

```bash
flutter test integration_test/
```

### Credentials de Test

Pour tester l'application rapidement, utilisez ces identifiants :

- **Email** : `john@test.com`
- **Mot de passe** : `password123`

> 💡 **Astuce** : Sur la page de connexion, appuyez longuement sur le logo pour remplir automatiquement ces identifiants.

---

## 🚢 Déploiement

### Android (APK)

```bash
flutter build apk --release
```

Le fichier APK sera généré dans : `build/app/outputs/flutter-apk/app-release.apk`

### Android (App Bundle)

```bash
flutter build appbundle --release
```

### iOS (IPA)

```bash
flutter build ios --release
```

---

## 🐛 Dépannage

### Problème : "Cannot connect to server"

**Solution** : Vérifiez que Django est en cours d'exécution et que l'URL dans `dio_client.dart` est correcte.

```bash
# Vérifier Django
curl http://10.0.2.2:8000/api/evenements/
```

### Problème : "Token expired" ou 401 Unauthorized

**Solution** : L'application se déconnecte automatiquement. Reconnectez-vous.

### Problème : "Solde insuffisant"

**Solution** : Rechargez votre portefeuille depuis la page Profil.

### Problème : Émulateur Android lent

**Solution** : Activez l'accélération matérielle dans Android Studio (Intel HAXM ou AMD Hypervisor).

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Forkez le projet
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add AmazingFeature'`)
4. Pushez vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

---

## 📝 Changelog

### Version 1.0.0 (2026-02-10)

- ✅ Authentification JWT avec Django
- ✅ Système de Wallet avec recharge
- ✅ Achat de billets avec QR Codes
- ✅ Recherche et filtres d'événements
- ✅ Géolocalisation et Google Maps
- ✅ Recommandations par IA
- ✅ Interface 6 onglets avec animations
- ✅ Support Android et iOS

---

## 📞 Support

Pour toute question ou problème :

- **Email** : support@eventmaster.com
- **Documentation Backend** : Voir le README du projet Django
- **Issues GitHub** : [Ouvrir un ticket](https://github.com/votre-organisation/event_app/issues)

---

## 👥 Équipe

- **Design Original** : [Andri.](https://dribbble.com/andri145) - [Event App Design](https://dribbble.com/shots/17444328-Event-Mobile-Apps-Design)
- **Développement Mobile** : Votre Équipe Flutter
- **Backend Django** : Votre Équipe Backend

---

## 🙏 Crédits

- [Flutter](https://flutter.dev) - Framework cross-platform
- [Andri.](https://dribbble.com/andri145) - Design original de l'interface
- [Django REST Framework](https://www.django-rest-framework.org/) - Backend API
- [PostgreSQL](https://www.postgresql.org/) - Base de données

---

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

```
MIT License

Copyright (c) 2026 EventMaster

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">

**Fait avec ❤️ par l'équipe EventMaster**

[⬆ Retour en haut](#-eventmaster-mobile)

</div>
