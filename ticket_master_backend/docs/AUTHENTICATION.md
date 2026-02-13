# Système d'authentification et de permissions

## Vue d'ensemble

Le backend utilise un système d'authentification JWT avec des permissions granulaires pour contrôler l'accès aux endpoints.

## Authentification JWT

### Fonctionnement

1. **Connexion** : L'utilisateur/admin s'authentifie via `/api/auth/login/`
2. **Token** : Un token JWT est généré avec le rôle (admin/user)
3. **Utilisation** : Le token est envoyé dans le header `Authorization: Bearer <token>`
4. **Validation** : Le backend vérifie le token et charge l'utilisateur correspondant

### Générer un token

```python
from tickets.utils.authentication import generate_jwt_token

# Pour un administrateur
token, expiration = generate_jwt_token(
    user_id=admin.id_admin,
    email=admin.email,
    role='admin',
    expiration_hours=24
)

# Pour un utilisateur
token, expiration = generate_jwt_token(
    user_id=user.id_utilisateur,
    email=user.email,
    role='user',
    expiration_hours=24
)
```

### Utiliser le token dans les requêtes

```bash
curl -X POST http://localhost:8000/api/evenements/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"titre_evenement": "Concert"}'
```

## Permissions disponibles

### 1. `AllowAny`
✅ Tout le monde peut accéder (avec ou sans authentification)

```python
from rest_framework.permissions import AllowAny

class MyViewSet(viewsets.ModelViewSet):
    permission_classes = [AllowAny]
```

### 2. `IsAdministrateur`
🔒 Seuls les administrateurs authentifiés (role='admin' dans le JWT)

```python
from tickets.permission import IsAdministrateur

class MyViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdministrateur]
```

### 3. `IsUtilisateur`
👤 Utilisateurs authentifiés (admin ou user)

```python
from tickets.permission import IsUtilisateur

class MyViewSet(viewsets.ModelViewSet):
    permission_classes = [IsUtilisateur]
```

### 4. `IsAdminOrReadOnly`
📖 Lecture publique, modification réservée aux admins

```python
from tickets.permission import IsAdminOrReadOnly

class MyViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminOrReadOnly]
```

## Permissions dynamiques par action

Pour appliquer des permissions différentes selon l'action (create, list, etc.) :

```python
class EvenementViewSet(viewsets.ModelViewSet):
    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            # Actions de modification : admin uniquement
            permission_classes = [IsAdministrateur]
        else:
            # Actions de consultation : tout le monde
            permission_classes = [AllowAny]
        
        return [permission() for permission in permission_classes]
```

## Configuration actuelle par ressource

### Événements
- ✅ **Consultation** (GET) : Public (AllowAny)
- 🔒 **Création/Modification/Suppression** : Administrateurs uniquement

### Utilisateurs
- ✅ **Toutes actions** : Public (AllowAny) ⚠️ À sécuriser en production

### Administrateurs
- ✅ **Toutes actions** : Public (AllowAny) ⚠️ À sécuriser en production

### Tickets
- ✅ **Toutes actions** : Public (AllowAny) ⚠️ À sécuriser en production

### Achats
- ✅ **Toutes actions** : Public (AllowAny) ⚠️ À sécuriser en production

## Recommandations de sécurité

### Pour la production

1. **Utilisateurs** : Restreindre create aux admins, update/delete au propriétaire ou admin
2. **Administrateurs** : Restreindre toutes les actions aux super-admins
3. **Tickets** : Restreindre create/update/delete aux admins
4. **Achats** : Restreindre create aux utilisateurs authentifiés, consultation au propriétaire/admin

### Exemple de sécurisation pour les achats

```python
class AchatViewSet(viewsets.ModelViewSet):
    def get_permissions(self):
        if self.action == 'create':
            # Achat : utilisateur authentifié uniquement
            permission_classes = [IsUtilisateur]
        elif self.action in ['list', 'retrieve']:
            # Consultation : propriétaire ou admin
            permission_classes = [IsAuthenticated]
        elif self.action == 'destroy':
            # Annulation : propriétaire ou admin
            permission_classes = [IsAuthenticated]
        else:
            # Stats : admins uniquement
            permission_classes = [IsAdministrateur]
        
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        # Filtrer les achats selon le rôle
        user = self.request.user
        if hasattr(user, 'is_admin') and user.is_admin:
            return Achat.objects.all()
        return Achat.objects.filter(id_utilisateur=user.id_utilisateur)
```

## Tester l'authentification

### 1. Obtenir un token

```bash
# Connexion admin
curl -X POST http://localhost:8000/api/auth/login/admin/ \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "mot_de_passe": "password123"}'

# Réponse
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbG...",
  "expiration": "2026-02-08T12:00:00",
  "administrateur": {...}
}
```

### 2. Utiliser le token

```bash
# Créer un événement (nécessite admin)
curl -X POST http://localhost:8000/api/evenements/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "titre_evenement": "Concert Jazz",
    "date": "2026-03-15",
    "lieu": "Paris",
    "type_evenement": "concert"
  }'
```

### 3. Vérifier un token

```bash
curl -X POST http://localhost:8000/api/auth/verify-token/ \
  -H "Content-Type: application/json" \
  -d '{"token": "eyJ0eXAiOiJKV1QiLCJhbG..."}'
```

## Erreurs courantes

### 401 Unauthorized
- Token manquant ou invalide
- Token expiré
- Format du header incorrect (doit être `Bearer <token>`)

### 403 Forbidden
- Token valide mais permissions insuffisantes
- Utilisateur inactif (statut != 'actif')
- Mauvais rôle (ex: user essaye d'accéder à une ressource admin)

## Configuration dans settings.py

```python
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'tickets.utils.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
}
```

L'authentification JWT est active par défaut sur tous les endpoints, mais les permissions par défaut sont `AllowAny` pour faciliter le développement.
