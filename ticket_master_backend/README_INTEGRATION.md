# 📱 Intégration Web & Mobile - Contrat Technique API

Ce document définit le **contrat technique strict** entre l'API Django (Backend) et le Frontend React (Admin). 
Le respect de ces spécifications est **CRITIQUE** pour garantir que l'application mobile affiche correctement les données (pas de champs "null", pas de crashs).

---

## 1. Authentification Utilisateur (JWT)

Tout échange avec l'API nécessite un token JWT valide (sauf Login/Register).

### 📝 Inscription (Register)
**Endpoint :** `POST /api/utilisateurs/`

| Champ | Type | Obligatoire | Description |
| :--- | :---: | :---: | :--- |
| `nom` | String | ✅ OUI | Nom de famille de l'utilisateur |
| `prenom` | String | ✅ OUI | Prénom de l'utilisateur |
| `email` | String | ✅ OUI | Email unique (sert d'identifiant) |
| `tel` | String | ✅ OUI | Format international recommandé (ex: +228...) |
| `mot_de_passe` | String | ✅ OUI | Min 8 caractères |
| `mot_de_passe_confirmation` | String | ✅ OUI | Doit être identique au mot de passe |
| `nom_utilisateur` | String | ❌ NON | Nom d'utilisateur unique (optionnel) |
| `adresse` | String | ❌ NON | Adresse de l'utilisateur (optionnelle) |
| `code_parrainage_utilise` | String | ❌ NON | Code de parrainage d'un autre utilisateur (6 caractères) |

**Réponse (Succès 201) :**
```json
{
    "message": "Inscription réussie. Vous êtes maintenant connecté.",
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "expiration": "2026-02-12T10:30:00Z",
    "utilisateur": {
        "id_utilisateur": 1,
        "nom": "Doe",
        "prenom": "John",
        "nom_complet": "John Doe",
        "email": "john@example.com",
        "tel": "+22890123456",
        "statut": "actif",
        "solde": 0.00,
        "code_parrainage": "A1B2C3"
    }
}
```

💡 **Système de Parrainage :** Si vous utilisez un code de parrainage valide lors de l'inscription, le parrain reçoit automatiquement **100 FCFA** sur son compte.

### 🔑 Connexion (Login)
**Endpoint :** `POST /api/auth/login/utilisateur/` (ou `/admin/` pour le back-office)

| Champ | Type | Obligatoire | Description |
| :--- | :---: | :---: | :--- |
| `email` | String | ✅ OUI | Email de l'utilisateur |
| `mot_de_passe` | String | ✅ OUI | Mot de passe |

**Réponse (Succès 200) :**
```json
{
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "utilisateur": { ... }
}
```
⚠️ **IMPORTANT :** Le Frontend DOIT stocker ce token et l'envoyer dans le header `Authorization: Bearer <TOKEN>` pour toutes les requêtes suivantes.

---

## 2. Gestion des Événements (Back-Office Admin)

L'application mobile dépend entièrement de ces données pour l'affichage et la navigation GPS.

### 📅 Création d'Événement
**Endpoint :** `POST /api/evenements/`

| Champ | Type | Obligatoire | Validation / Contraintes |
| :--- | :---: | :---: | :--- |
| `titre_evenement` | String | ✅ OUI | Max 100 char. Titre clair et accrocheur. |
| `type_evenement` | String | ✅ OUI | **VALEURS STRICTES :** `Music`, `Tech`, `Art`, `Sport`, `Food`, `Tourism`. <br>(Sinon l'icône mobile sera par défaut) |
| `lieu` | String | ✅ OUI | Nom du lieu (ex: "Palais des Congrès"). |
| `image` | String (URL) | ✅ OUI | URL directe vers l'image. Format JPG/PNG. <br>Utilisée en couverture ("Hero Image") sur mobile. |
| `date` | Date | ✅ OUI | Format `YYYY-MM-DD`. Date principale de l'événement. |
| `latitude` | Float | ⚠️ FORTEMENT RECOMMANDÉ | Pour la navigation GPS. Ex: `6.1311` |
| `longitude` | Float | ⚠️ FORTEMENT RECOMMANDÉ | Pour la navigation GPS. Ex: `1.2132` |

### 🕒 Sessions (Créneaux Horaires)
Chaque événement **DOIT** avoir au moins une session pour que l'utilisateur puisse choisir une date.

**Endpoint :** `POST /api/sessions/`

| Champ | Type | Description |
| :--- | :---: | :--- |
| `evenement` | ID | ID de l'événement parent. |
| `date_heure` | DateTime | Format ISO 8601 : `YYYY-MM-DDTHH:MM:SS`. |

---

## 3. Gestion des Billets (Tickets)

Les tickets définissent le prix et le stock. Un événement peut avoir plusieurs types de tickets.

**Endpoint :** `POST /api/tickets/`

| Champ | Type | Obligatoire | Description |
| :--- | :---: | :---: | :--- |
| `id_evenement` | ID | ✅ OUI | ID de l'événement associé. |
| `type` | String | ✅ OUI | Ex: `VIP`, `Standard`, `VVIP`, `Early Bird`. |
| `prix` | Decimal | ✅ OUI | Montant en **FCFA**. 0 pour gratuit. |
| `stock` | Integer | ✅ OUI | Nombre de places disponibles au total. |

---

## 4. Portefeuille & Transactions (Wallet)

Le système gère automatiquement le solde utilisateur.

### 💰 Recharger le Compte
**Endpoint :** `POST /api/utilisateurs/{id}/recharger/`

| Champ | Type | Description |
| :--- | :---: | :--- |
| `montant` | Decimal | Montant à ajouter au solde (en FCFA). |

### 🛍️ Processus d'Achat
**Endpoint :** `POST /api/achats/`

Le Frontend n'a PAS besoin de calculer le nouveau solde. Le Backend gère :
1. Vérification du solde disponible.
2. Vérification du stock ticket.
3. Débit du solde utilisateur.
4. Décrémentation du stock ticket.
5. Création de la transaction.

**Payload Requis :**
```json
{
    "id_ticket": 12,
    "quantite": 2
    // id_utilisateur : NON REQUIS (déduit du token JWT)
}
```

---

## 5. Formats de Données Standards

Pour garantir une harmonie totale entre le Web Admin et le Mobile :

*   **Devise :** Tous les montants sont en **FCFA** (XOF). Aucun symbole de devise dans la base de données, uniquement le nombre.
*   **Dates :** Toujours utiliser le format **ISO 8601** (`YYYY-MM-DD` ou `YYYY-MM-DDTHH:MM:SS`) pour les envois et réceptions.
*   **Images :** Fournir des **URL absolues** (ex: `https://monsite.com/images/concert.jpg`). Le mobile ne gère pas les uploads de fichiers binaires pour le moment, uniquement les liens.
*   **Types d'Événements :** Respectez la casse (`Music`, pas `music` ou `Musique`) pour que les filtres de catégories mobiles fonctionnent.

---

**Ce document doit être la référence unique pour tout développement Web/Admin.**
Toute déviation entraînera des erreurs d'affichage ou fonctionnelles sur l'application mobile Flutter.
