# 📖 Documentation API - UTILISATEURS

## Table des matières
1. [Authentification](#authentification)
2. [Gestion des Utilisateurs](#gestion-des-utilisateurs)
3. [Formats de données](#formats-de-données)
4. [Gestion des erreurs](#gestion-des-erreurs)

---

## 🔐 Authentification

### 1. Connexion Utilisateur
**Endpoint:** `POST /api/auth/login/utilisateur/`  
**Permission:** Aucune (public)

#### Ce que le frontend doit envoyer :
```json
{
  "email": "user@example.com",           // OU nom_utilisateur (un des deux requis)
  "nom_utilisateur": "johndoe",          // OU email (un des deux requis)
  "mot_de_passe": "motdepasse123",       // REQUIS
  "remember_me": false                   // OPTIONNEL (par défaut: false)
}
```

#### Réponse en cas de succès (200) :
```json
{
  "message": "Authentification réussie",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiration": "2026-02-09T12:00:00",
  "remember_me": false,
  "utilisateur": {
    "id_utilisateur": 1,
    "nom": "DOE",
    "prenom": "John",
    "nom_complet": "John DOE",
    "email": "user@example.com",
    "statut": "actif",
    "solde": 0.0,
    "tel": "+33612345678",
    "photo_profil": "http://localhost:8000/media/utilisateurs/profile.jpg",
    "last_login": "2026-02-08T10:30:00",
    "nom_utilisateur": "johndoe",
    "total_code_use": 0,
    "code_parrainage": "A7B2K9"
  }
}
```

#### Exemple JavaScript :
```javascript
const login = async (identifiant, motDePasse, rememberMe = false) => {
  const body = {
    mot_de_passe: motDePasse,
    remember_me: rememberMe
  };
  
  // Détection automatique si c'est un email ou nom d'utilisateur
  if (identifiant.includes('@')) {
    body.email = identifiant;
  } else {
    body.nom_utilisateur = identifiant;
  }
  
  const response = await fetch('http://localhost:8000/api/auth/login/utilisateur/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(body)
  });
  
  return await response.json();
};
```

#### Erreurs possibles :
- **400** : `"Tous les champs sont requis."`
- **401** : `"Identifiant ou mot de passe incorrect"`
- **403** : `"Votre compte est inactif. Contactez l'administrateur."`

---

## 👥 Gestion des Utilisateurs

### 2. Créer un Utilisateur (Inscription)
**Endpoint:** `POST /api/utilisateurs/`  
**Permission:** Aucune (public)

#### Ce que le frontend doit envoyer :
```json
{
  "nom": "DOE",                          // REQUIS
  "prenom": "John",                      // REQUIS
  "email": "user@example.com",           // REQUIS (unique)
  "mot_de_passe": "motdepasse123",       // REQUIS (min 8 caractères)
  "mot_de_passe_confirmation": "motdepasse123",  // REQUIS (doit correspondre)
  "tel": "+33612345678",                 // OPTIONNEL
  "nom_utilisateur": "johndoe",          // OPTIONNEL
  "adresse": "Lomé, Togo",               // OPTIONNEL
  "code_parrainage_utilise": "A7B2K9"    // OPTIONNEL (code d'un autre utilisateur)
}
```

> **⚠️ NE PAS ENVOYER :** `code_parrainage`, `total_code_use`, `last_login`, `photo_profil`, `solde`, `statut`  
> Ces champs sont générés/gérés automatiquement par le backend.

#### 🎁 Système de parrainage

**Comment ça marche ?**

1. **Utilisateur A** s'inscrit → Reçoit automatiquement un code de parrainage unique (ex: `A7B2K9`)
2. **Utilisateur B** s'inscrit en indiquant le code de parrainage de A dans `code_parrainage_utilise`
3. **Utilisateur A** reçoit automatiquement **+100 FCFA** sur son solde
4. Une transaction de type `bonus_parrainage` est créée dans l'historique de A

**Règles :**
- ✅ Le champ `code_parrainage_utilise` est **OPTIONNEL**
- ✅ Le code peut être saisi en **minuscules** ou **majuscules** (converti automatiquement)
- ✅ Le code doit exister dans la base de données
- ✅ Bonus : **100 FCFA** ajoutés au parrain
- ✅ Le compteur `total_code_use` du parrain est incrémenté

**Exemples valides :**
```json
// Code en majuscules
"code_parrainage_utilise": "A7B2K9"

// Code en minuscules (converti automatiquement en A7B2K9)
"code_parrainage_utilise": "a7b2k9"

// Code mixte (converti automatiquement en A7B2K9)
"code_parrainage_utilise": "A7b2K9"

// Pas de code (inscription normale sans parrainage)
// Omettre le champ ou envoyer une chaîne vide
"code_parrainage_utilise": ""
```

#### Réponse en cas de succès (201) :

**Sans code de parrainage :**
```json
{
  "id_utilisateur": 1,
  "nom": "DOE",
  "prenom": "John",
  "email": "user@example.com",
  "statut": "actif",
  "solde": 0.0,
  "tel": "+33612345678",
  "photo_profil": null,
  "last_login": null,
  "nom_utilisateur": "johndoe",
  "adresse": "Lomé, Togo",
  "total_code_use": 0,
  "code_parrainage": "X9K4M2"    // ✅ Code généré automatiquement (6 caractères)
}
```

**Avec code de parrainage valide :**
```json
{
  "id_utilisateur": 2,
  "nom": "KOUADIO",
  "prenom": "Marie",
  "email": "marie@example.com",
  "statut": "actif",
  "solde": 0.0,
  "tel": "+228 90 12 34 56",
  "photo_profil": null,
  "last_login": null,
  "nom_utilisateur": "mariekouadio",
  "adresse": "Abidjan, Côte d'Ivoire",
  "total_code_use": 0,
  "code_parrainage": "P5T8W1"    // ✅ Nouveau code unique généré
}
```

> **Note :** L'utilisateur qui a fourni le code de parrainage (`A7B2K9` dans cet exemple) reçoit automatiquement +100 FCFA. L'utilisateur nouvellement inscrit ne reçoit pas de bonus, mais obtient son propre code pour parrainer d'autres personnes.

#### Exemple JavaScript :

**Inscription sans code de parrainage :**
```javascript
const inscrireUtilisateur = async (userData) => {
  const response = await fetch('http://localhost:8000/api/utilisateurs/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      nom: userData.nom,
      prenom: userData.prenom,
      email: userData.email,
      mot_de_passe: userData.motDePasse,
      mot_de_passe_confirmation: userData.motDePasseConfirmation,
      tel: userData.tel || '',
      nom_utilisateur: userData.nomUtilisateur || '',
      adresse: userData.adresse || ''
    })
  });
  
  return await response.json();
};
```

**Inscription avec code de parrainage :**
```javascript
const inscrireAvecParrainage = async (userData, codeParrainage) => {
  const response = await fetch('http://localhost:8000/api/utilisateurs/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      nom: userData.nom,
      prenom: userData.prenom,
      email: userData.email,
      mot_de_passe: userData.motDePasse,
      mot_de_passe_confirmation: userData.motDePasseConfirmation,
      tel: userData.tel || '',
      nom_utilisateur: userData.nomUtilisateur || '',
      adresse: userData.adresse || '',
      code_parrainage_utilise: codeParrainage  // ← Code du parrain
    })
  });
  
  return await response.json();
};

// Utilisation
await inscrireAvecParrainage({
  nom: 'KOUADIO',
  prenom: 'Marie',
  email: 'marie@example.com',
  motDePasse: 'Password123',
  motDePasseConfirmation: 'Password123',
  tel: '+228 90 12 34 56'
}, 'a7b2k9');  // ← Le code sera converti en A7B2K9
```

#### Erreurs possibles :
- **400** : Validation échouée
  ```json
  {
    "email": ["Un utilisateur avec cet email existe déjà."],
    "mot_de_passe": ["Le mot de passe doit contenir au moins 8 caractères."],
    "mot_de_passe_confirmation": ["Les mots de passe ne correspondent pas."],
    "code_parrainage_utilise": ["Ce code de parrainage n'existe pas."]
  }
  ```

**Exemples d'erreurs spécifiques :**

```json
// Code de parrainage invalide
{
  "code_parrainage_utilise": ["Ce code de parrainage n'existe pas."]
}

// Email déjà utilisé
{
  "email": ["Un utilisateur avec cet email existe déjà."]
}

// Mot de passe trop court
{
  "mot_de_passe": ["Le mot de passe doit contenir au moins 8 caractères."]
}

// Mots de passe différents
{
  "mot_de_passe_confirmation": ["Les mots de passe ne correspondent pas."]
}
```

---

### 3. Lister les Utilisateurs
**Endpoint:** `GET /api/utilisateurs/`  
**Permission:** Token JWT requis

#### Ce que le frontend doit envoyer :
**Headers uniquement :**
```javascript
{
  "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Réponse (200) :
```json
{
  "count": 50,
  "next": "http://localhost:8000/api/utilisateurs/?page=2",
  "previous": null,
  "results": [
    {
      "id_utilisateur": 1,
      "nom": "DOE",
      "prenom": "John",
      "nom_complet": "John DOE",
      "email": "user@example.com",
      "statut": "actif",
      "solde": 150.50,
      "tel": "+33612345678",
      "photo_profil": "http://localhost:8000/media/utilisateurs/profile.jpg",
      "last_login": "2026-02-08T10:30:00",
      "nom_utilisateur": "johndoe",
      "total_code_use": 5,
      "code_parrainage": "A7B2K9"
    }
    // ... autres utilisateurs
  ]
}
```

#### Exemple JavaScript :
```javascript
const getUtilisateurs = async (token, page = 1) => {
  const response = await fetch(`http://localhost:8000/api/utilisateurs/?page=${page}`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  return await response.json();
};
```

---

### 4. Obtenir les Détails d'un Utilisateur
**Endpoint:** `GET /api/utilisateurs/{id}/`  
**Permission:** Token JWT requis

#### Ce que le frontend doit envoyer :
**Headers uniquement :**
```javascript
{
  "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Réponse (200) :
```json
{
  "id_utilisateur": 1,
  "nom": "DOE",
  "prenom": "John",
  "nom_complet": "John DOE",
  "email": "user@example.com",
  "statut": "actif",
  "solde": 150.50,
  "tel": "+33612345678",
  "photo_profil": "http://localhost:8000/media/utilisateurs/profile.jpg",
  "last_login": "2026-02-08T10:30:00",
  "nom_utilisateur": "johndoe",
  "total_code_use": 5,
  "code_parrainage": "A7B2K9"
}
```

---

### 5. Modifier un Utilisateur (PUT - Mise à jour complète)
**Endpoint:** `PUT /api/utilisateurs/{id}/`  
**Permission:** Token JWT requis (Administrateur)

#### Ce que le frontend doit envoyer :
**Avec fichier photo :**
```javascript
const formData = new FormData();
formData.append('nom', 'NOUVEAU_NOM');
formData.append('prenom', 'NOUVEAU_PRENOM');
formData.append('email', 'nouveau@email.com');
formData.append('tel', '+33612345678');
formData.append('statut', 'actif');
formData.append('nom_utilisateur', 'newusername');
// Si modification du mot de passe
formData.append('mot_de_passe', 'nouveaumotdepasse');
formData.append('mot_de_passe_confirmation', 'nouveaumotdepasse');
// Si modification de la photo
formData.append('photo_profil', photoFile);  // File object
```

**Sans fichier (JSON) :**
```json
{
  "nom": "NOUVEAU_NOM",
  "prenom": "NOUVEAU_PRENOM",
  "email": "nouveau@email.com",
  "tel": "+33612345678",
  "statut": "actif",
  "nom_utilisateur": "newusername",
  "mot_de_passe": "nouveaumotdepasse",           // OPTIONNEL
  "mot_de_passe_confirmation": "nouveaumotdepasse"  // REQUIS si mot_de_passe envoyé
}
```

#### Exemple JavaScript :
```javascript
const updateUtilisateur = async (token, id, userData, photoFile = null) => {
  const formData = new FormData();
  
  // Ajouter tous les champs
  Object.keys(userData).forEach(key => {
    if (userData[key] !== null && userData[key] !== undefined) {
      formData.append(key, userData[key]);
    }
  });
  
  // Ajouter la photo si présente
  if (photoFile) {
    formData.append('photo_profil', photoFile);
  }
  
  const response = await fetch(`http://localhost:8000/api/utilisateurs/${id}/`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`
      // ❌ NE PAS ajouter Content-Type avec FormData
    },
    body: formData
  });
  
  return await response.json();
};
```

---

### 6. Modifier un Utilisateur (PATCH - Mise à jour partielle)
**Endpoint:** `PATCH /api/utilisateurs/{id}/`  
**Permission:** Token JWT requis (Administrateur ou propriétaire du compte)

#### Ce que le frontend doit envoyer :
**Modifier uniquement la photo de profil :**
```javascript
const formData = new FormData();
formData.append('photo_profil', photoFile);
```

**Modifier uniquement l'email :**
```javascript
const formData = new FormData();
formData.append('email', 'nouveau@email.com');
```

**Modifier plusieurs champs :**
```javascript
const formData = new FormData();
formData.append('nom', 'NOUVEAU_NOM');
formData.append('prenom', 'NOUVEAU_PRENOM');
formData.append('tel', '+33698765432');
formData.append('photo_profil', photoFile);
```

#### Exemple JavaScript :
```javascript
const updateProfilPartiel = async (token, id, updates) => {
  const formData = new FormData();
  
  // Ajouter uniquement les champs à modifier
  Object.keys(updates).forEach(key => {
    if (updates[key] !== null && updates[key] !== undefined) {
      formData.append(key, updates[key]);
    }
  });
  
  const response = await fetch(`http://localhost:8000/api/utilisateurs/${id}/`, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`
      // ❌ PAS de Content-Type avec FormData
    },
    body: formData
  });
  
  return await response.json();
};

// Exemples d'utilisation
updateProfilPartiel(token, 1, { nom: 'DUPONT' });
updateProfilPartiel(token, 1, { photo_profil: fileInput.files[0] });
updateProfilPartiel(token, 1, { 
  email: 'new@email.com',
  tel: '+33612345678'
});
```

#### Réponse (200) :
```json
{
  "id_utilisateur": 1,
  "nom": "NOUVEAU_NOM",
  "prenom": "NOUVEAU_PRENOM",
  "email": "nouveau@email.com",
  "statut": "actif",
  "solde": 150.50,
  "tel": "+33698765432",
  "photo_profil": "http://localhost:8000/media/utilisateurs/new_profile.jpg",
  "last_login": "2026-02-08T10:30:00",
  "nom_utilisateur": "newusername",
  "total_code_use": 5,
  "code_parrainage": "A7B2K9"
}
```

---

### 7. Supprimer un Utilisateur
**Endpoint:** `DELETE /api/utilisateurs/{id}/`  
**Permission:** Token JWT requis (Administrateur uniquement)

#### Ce que le frontend doit envoyer :
**Headers uniquement :**
```javascript
{
  "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Réponse (204) :
Aucun contenu (suppression réussie)

#### Exemple JavaScript :
```javascript
const supprimerUtilisateur = async (token, id) => {
  const response = await fetch(`http://localhost:8000/api/utilisateurs/${id}/`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  if (response.status === 204) {
    return { success: true };
  }
  return await response.json();
};
```

---

### 8. Changer le Mot de Passe
**Endpoint:** `POST /api/utilisateurs/{id}/changer-mot-de-passe/`  
**Permission:** Token JWT requis (Utilisateur authentifié)

#### Ce que le frontend doit envoyer :
```json
{
  "ancien_mot_de_passe": "ancienpass123",           // REQUIS
  "nouveau_mot_de_passe": "NouveauPass123",         // REQUIS (min 8 caractères, 1 chiffre, 1 majuscule)
  "nouveau_mot_de_passe_confirmation": "NouveauPass123"  // REQUIS
}
```

#### Réponse en cas de succès (200) :
```json
{
  "message": "Mot de passe modifié avec succès"
}
```

#### Exemple JavaScript :
```javascript
const changerMotDePasse = async (token, id, passwords) => {
  const response = await fetch(`http://localhost:8000/api/utilisateurs/${id}/changer-mot-de-passe/`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      ancien_mot_de_passe: passwords.ancienMotDePasse,
      nouveau_mot_de_passe: passwords.nouveauMotDePasse,
      nouveau_mot_de_passe_confirmation: passwords.nouveauMotDePasseConfirmation
    })
  });
  
  return await response.json();
};
```

#### Erreurs possibles :
- **400** : Validation échouée
  ```json
  {
    "nouveau_mot_de_passe": ["Le mot de passe doit contenir au moins un chiffre."],
    "nouveau_mot_de_passe_confirmation": ["Les mots de passe ne correspondent pas."]
  }
  ```

---

## 📋 Formats de données

### Champs du modèle Utilisateur

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `id_utilisateur` | Integer | Auto | ID unique (primary key) |
| `nom` | String | ✅ Création | Nom de famille |
| `prenom` | String | ✅ Création | Prénom |
| `email` | String | ✅ Création | Email unique |
| `mot_de_passe` | String | ✅ Création | Mot de passe (hashé) |
| `tel` | String | ❌ | Numéro de téléphone |
| `adresse` | String | ❌ | Adresse complète de l'utilisateur |
| `nom_utilisateur` | String | ❌ | Nom d'utilisateur (unique) |
| `statut` | String | Auto | `actif`, `inactif` (défaut: `actif`) |
| `solde` | Decimal | Auto | Solde du compte (défaut: 0.0) |
| `photo_profil` | File/Image | ❌ | Photo de profil (upload) |
| `last_login` | DateTime | Auto | Dernière connexion |
| `total_code_use` | Integer | Auto | Nombre d'utilisations du code de parrainage |
| `code_parrainage` | String | Auto | Code de parrainage unique (6 caractères) généré automatiquement |
| `code_parrainage_utilise` | String | ❌ Création uniquement | Code de parrainage d'un autre utilisateur (pour recevoir le bonus) |

### Règles de validation

#### Mot de passe (création) :
- Minimum 8 caractères
- Requis + confirmation

#### Code de parrainage (lors de l'inscription) :
- Optionnel
- 6 caractères alphanumériques
- Accepte minuscules/majuscules (converti automatiquement en majuscules)
- Doit exister dans la base de données
- **Effet :** Ajoute 100 FCFA au solde du parrain

#### Mot de passe (changement) :
- Minimum 8 caractères
- Au moins 1 chiffre
- Au moins 1 majuscule
- Requis + confirmation

#### Email :
- Format email valide
- Unique dans la base de données
- Converti en minuscules

#### Photo de profil :
- Formats acceptés : JPG, JPEG, PNG, GIF, WEBP
- Taille maximale : 5 MB
- Upload via FormData

---

## ⚠️ Gestion des erreurs

### Codes de statut HTTP

| Code | Description |
|------|-------------|
| `200` | Succès (GET, PUT, PATCH) |
| `201` | Création réussie (POST) |
| `204` | Suppression réussie (DELETE) |
| `400` | Erreur de validation |
| `401` | Non authentifié / Token invalide |
| `403` | Accès interdit (permissions insuffisantes) |
| `404` | Ressource non trouvée |
| `500` | Erreur serveur |

### Format des erreurs

**Erreur de validation (400) :**
```json
{
  "email": ["Un utilisateur avec cet email existe déjà."],
  "mot_de_passe": ["Le mot de passe doit contenir au moins 8 caractères."]
}
```

**Erreur d'authentification (401) :**
```json
{
  "error": "Identifiant ou mot de passe incorrect"
}
```

**Erreur de permission (403) :**
```json
{
  "detail": "Vous n'avez pas la permission d'effectuer cette action."
}
```

---

## 🔑 Checklist Frontend - Utilisateurs

### ✅ À FAIRE lors de l'envoi de fichiers (photo_profil) :

```javascript
✅ Utiliser FormData pour l'upload de fichiers
✅ Ajouter le fichier avec .append('photo_profil', fileObject)
✅ Utiliser fileInput.files[0] (pas le chemin)
✅ Ajouter uniquement le header Authorization
✅ Ne PAS ajouter Content-Type (le navigateur le fait automatiquement avec FormData)
```

### ❌ NE PAS FAIRE :

```javascript
❌ N'envoie PAS de JSON lorsque tu uploads un fichier
❌ Ne définis PAS Content-Type: 'multipart/form-data' manuellement
❌ N'envoie PAS le chemin du fichier (C:\\Users\\...), envoie l'objet File
❌ N'encode PAS en base64 pour l'upload
❌ Ne mélange PAS JSON et FormData dans le même appel
❌ N'oublie PAS le token Authorization pour les routes protégées
❌ N'envoie PAS code_parrainage, total_code_use, last_login lors de la création
```

### Exemple complet - Inscription avec photo :

```javascript
const inscrireAvecPhoto = async (userData, photoFile) => {
  const formData = new FormData();
  
  // Champs requis
  formData.append('nom', userData.nom);
  formData.append('prenom', userData.prenom);
  formData.append('email', userData.email);
  formData.append('mot_de_passe', userData.motDePasse);
  formData.append('mot_de_passe_confirmation', userData.motDePasseConfirmation);
  
  // Champs optionnels
  if (userData.tel) formData.append('tel', userData.tel);
  if (userData.nomUtilisateur) formData.append('nom_utilisateur', userData.nomUtilisateur);
  
  // Photo (si présente)
  if (photoFile) {
    formData.append('photo_profil', photoFile);
  }
  
  const response = await fetch('http://localhost:8000/api/utilisateurs/', {
    method: 'POST',
    // ❌ PAS de Content-Type ici !
    body: formData
  });
  
  return await response.json();
};
```

---

## 📌 Récapitulatif des URLs

| Action | Méthode | URL | Permission |
|--------|---------|-----|------------|
| Connexion | POST | `/api/auth/login/utilisateur/` | Public |
| Créer | POST | `/api/utilisateurs/` | Public |
| Liste | GET | `/api/utilisateurs/` | JWT Token |
| Détails | GET | `/api/utilisateurs/{id}/` | JWT Token |
| Modifier (complet) | PUT | `/api/utilisateurs/{id}/` | JWT Token (Admin) |
| Modifier (partiel) | PATCH | `/api/utilisateurs/{id}/` | JWT Token (Admin/Propriétaire) |
| Supprimer | DELETE | `/api/utilisateurs/{id}/` | JWT Token (Admin) |
| Changer mot de passe | POST | `/api/utilisateurs/{id}/changer-mot-de-passe/` | JWT Token (Propriétaire) |

---

**Base URL:** `http://localhost:8000`  
**Token JWT:** Valable 24h (ou 7 jours avec `remember_me=true`)  
**Format:** Authorization: Bearer {token}
