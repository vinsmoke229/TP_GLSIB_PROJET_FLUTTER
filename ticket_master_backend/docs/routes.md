# Structure des URLs de l'API Ticket Backend

Ce dossier contient tous les fichiers de configuration des URLs, organisés par catégorie.

## Organisation

```
tickets/urls/
├── __init__.py           # Point d'entrée principal regroupant toutes les routes
├── auth_urls.py          # Routes d'authentification
├── utilisateur_urls.py   # Routes pour la gestion des utilisateurs
├── admin_urls.py         # Routes pour la gestion des administrateurs
├── evenement_urls.py     # Routes pour la gestion des événements
├── ticket_urls.py        # Routes pour la gestion des tickets
└── achat_urls.py         # Routes pour la gestion des achats
```

## Préfixe de base

Toutes les routes sont préfixées par `/api/` (configuré dans `Ticket/urls.py`)

## Catégories d'endpoints

### 🔐 Authentification (`/api/auth/`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/auth/login/admin/` | Connexion administrateur |
| POST | `/api/auth/login/utilisateur/` | Connexion utilisateur |
| POST | `/api/auth/verify-token/` | Vérifier un token JWT |
| POST | `/api/auth/logout/` | Déconnexion |

### 👤 Utilisateurs (`/api/utilisateurs/`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/utilisateurs/` | Liste tous les utilisateurs |
| POST | `/api/utilisateurs/` | Créer un utilisateur |
| GET | `/api/utilisateurs/{id}/` | Détails d'un utilisateur |
| PUT | `/api/utilisateurs/{id}/` | Mise à jour complète |
| PATCH | `/api/utilisateurs/{id}/` | Mise à jour partielle |
| DELETE | `/api/utilisateurs/{id}/` | Supprimer un utilisateur |
| POST | `/api/utilisateurs/{id}/desactiver/` | Désactiver un utilisateur |
| POST | `/api/utilisateurs/{id}/activer/` | Activer un utilisateur |
| POST | `/api/utilisateurs/{id}/changer_mot_de_passe/` | Changer le mot de passe |
| GET | `/api/utilisateurs/rechercher/?q=text` | Rechercher des utilisateurs |

### 👨‍💼 Administrateurs (`/api/administrateurs/`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/administrateurs/` | Liste tous les administrateurs |
| POST | `/api/administrateurs/` | Créer un administrateur |
| GET | `/api/administrateurs/{id}/` | Détails d'un administrateur |
| PUT | `/api/administrateurs/{id}/` | Mise à jour|
| DELETE | `/api/administrateurs/{id}/` | Supprimer un administrateur |
| POST | `/api/administrateurs/{id}/changer_mot_de_passe/` | Changer le mot de passe |
| GET | `/api/administrateurs/rechercher/?q=text` | Rechercher des administrateurs |
 POST /api/administrateurs/{id}/desactiver/
 POST /api/administrateurs/{id}/activer/

### 🎭 Événements (`/api/evenements/`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/evenements/` | Liste tous les événements |
| POST | `/api/evenements/` | Créer un événement |
| GET | `/api/evenements/{id}/` | Détails d'un événement |
| PUT | `/api/evenements/{id}/` | Mise à jour complète |
| PATCH | `/api/evenements/{id}/` | Mise à jour partielle |
| DELETE | `/api/evenements/{id}/` | Supprimer un événement |
| GET | `/api/evenements/a_venir/` | Événements à venir |
| GET | `/api/evenements/passes/` | Événements passés |
| GET | `/api/evenements/{id}/tickets/` | Tickets d'un événement |
| GET | `/api/evenements/par_type/?type=concert` | Filtrer par type |
| GET | `/api/evenements/rechercher/?q=text` | Rechercher des événements |

### 🎫 Tickets (`/api/tickets/`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/tickets/` | Liste tous les tickets |
| POST | `/api/tickets/` | Créer un ticket |
| GET | `/api/tickets/{id}/` | Détails d'un ticket |
| PUT | `/api/tickets/{id}/` | Mise à jour complète |
| PATCH | `/api/tickets/{id}/` | Mise à jour partielle |
| DELETE | `/api/tickets/{id}/` | Supprimer un ticket |
| GET | `/api/tickets/disponibles/` | Tickets disponibles |
| POST | `/api/tickets/{id}/modifier_stock/` | Modifier le stock |

### 🛒 Achats (`/api/achats/`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/achats/` | Liste tous les achats |
| POST | `/api/achats/` | Créer un achat |
| GET | `/api/achats/{id}/` | Détails d'un achat |
| DELETE | `/api/achats/{id}/` | Annuler un achat (< 24h) |
| GET | `/api/achats/par_utilisateur/?id_utilisateur=1` | Achats d'un utilisateur |
| GET | `/api/achats/par_evenement/?id_evenement=1` | Achats pour un événement |
| GET | `/api/achats/recents/` | Achats récents (< 24h) |
| GET | `/api/achats/statistiques/` | Statistiques d'achats |

## Exemples d'utilisation

### Authentification

```bash
# Connexion utilisateur
curl -X POST http://localhost:8000/api/auth/login/utilisateur/ \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "mot_de_passe": "password123"}'

# Vérifier un token
curl -X POST http://localhost:8000/api/auth/verify-token/ \
  -H "Content-Type: application/json" \
  -d '{"token": "votre_jwt_token"}'
```

### Gestion des ressources

```bash
# Lister tous les événements
curl http://localhost:8000/api/evenements/

# Créer un ticket
curl -X POST http://localhost:8000/api/tickets/ \
  -H "Content-Type: application/json" \
  -d '{"type": "VIP", "prix": 150, "stock": 100, "id_evenement": 1}'

# Rechercher des utilisateurs
curl http://localhost:8000/api/utilisateurs/rechercher/?q=jean
```
