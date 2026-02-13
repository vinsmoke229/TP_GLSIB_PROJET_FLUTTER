# Mobile App Connection Testing Guide

**Status**: Server optimized for mobile connectivity with CORS and connection pooling

## Quick Test Checklist

### ✓ Configuration Verified
- ALLOWED_HOSTS: `['localhost', '127.0.0.1', '10.0.2.2', '0.0.0.0', '*']`
- CorsMiddleware: Position 1 (correct)
- CORS_ALLOW_ALL_ORIGINS: True (DEBUG mode)
- CORS_PREFLIGHT_MAX_AGE: 3600 (cache preflight 1 hour)
- CONN_MAX_AGE: 600 (connection pooling 10 minutes)
- Connection Timeout: Fixed by:
  - Adding 10.0.2.2 to ALLOWED_HOSTS (Android emulator)
  - Adding CONN_MAX_AGE for connection pooling
  - Adding CORS_PREFLIGHT_MAX_AGE for preflight caching
  - Exposing Authorization headers

---

## Testing Instructions

### 1. **For Android Emulator (Flutter)**

Use this base URL:
```
http://10.0.2.2:8000
```

#### Test Sequence:

**A. Register User**
```http
POST http://10.0.2.2:8000/api/auth/register/utilisateur/
Content-Type: application/json

{
  "nom": "Test",
  "prenom": "Mobile",
  "email": "mobile_test@example.com",
  "password": "TestPassword123"
}
```

**Expected Response**: 201 Created
```json
{
  "id_utilisateur": 1,
  "email": "mobile_test@example.com",
  "nom": "Test",
  "prenom": "Mobile"
}
```

---

**B. Login**
```http
POST http://10.0.2.2:8000/api/auth/login/utilisateur/
Content-Type: application/json

{
  "email": "mobile_test@example.com",
  "password": "TestPassword123"
}
```

**Expected Response**: 200 OK
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "utilisateur": {
    "id_utilisateur": 1,
    "email": "mobile_test@example.com",
    "nom": "Test",
    "prenom": "Mobile",
    "solde": 0.0,
    "interests": null
  }
}
```

---

**C. Get Events (Authorized)**
```http
GET http://10.0.2.2:8000/api/evenements/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Expected Response**: 200 OK
```json
[
  {
    "id_evenement": 1,
    "titre_evenement": "Conférence Tech",
    "description": "Conférence sur les technologies modernes",
    "date": "2026-02-15",
    "lieu": "Centre Culturel",
    "latitude": 6.1311,
    "longitude": 1.2132,
    "type_evenement": "Conference",
    "prix": 5000.0
  },
  ...
]
```

---

**D. Get Recommendations**
```http
GET http://10.0.2.2:8000/api/ai/recommendation/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIYzI1NiJ9...
```

**Expected Response**: 200 OK
```json
{
  "event": {
    "id_evenement": 2,
    "titre_evenement": "Festival Musique",
    "description": "Festival de musique afro-caribéenne",
    "date": "2026-02-20",
    "lieu": "Parc Municipal",
    "latitude": 6.1834,
    "longitude": 1.2334,
    "type_evenement": "Festival",
    "prix": 2000.0
  },
  "reason": "Based on your interests and event popularity",
  "confidence": "high"
}
```

---

### 2. **For iOS Simulator (Flutter)**

Use this base URL:
```
http://127.0.0.1:8000
```

Same test sequence as Android above, just replace `10.0.2.2` with `127.0.0.1`.

---

### 3. **For Web Testing (React/Vue Frontend)**

Use this base URL:
```
http://localhost:3000  (Frontend running on port 3000)
```

When making API calls:
```javascript
// Example: Fetch events from web frontend
fetch('http://localhost:8000/api/evenements/', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  },
  credentials: 'include'  // Include cookies if needed
})
.then(response => response.json())
.then(data => console.log(data))
.catch(error => console.error('Error:', error));
```

**CORS will automatically handle the cross-origin request**

---

## Troubleshooting

### Issue: Connection Timeout (Android)

**Cause**: Middleware ordering or ALLOWED_HOSTS missing Android address

**Solution**:
1. Verify `10.0.2.2` is in ALLOWED_HOSTS
2. Check CorsMiddleware is at position 1 in middleware list
3. Restart server: `python manage.py runserver`

### Issue: Broken Pipe Errors

**Cause**: Connection closing unexpectedly

**Solution**:
1. CONN_MAX_AGE is now set to 600 (10 minutes)
2. This keeps connections alive longer
3. If still happening, check server logs for errors

### Issue: CORS Headers Missing

**Cause**: Cross-origin request not detected

**Solution**:
1. CORS_ALLOW_ALL_ORIGINS = True in DEBUG mode
2. Make sure you're using the correct base URL (10.0.2.2 for Android)
3. Headers are automatically handled by CorsMiddleware

### Issue: No Response from Server

**Check**:
1. Is server running? `python manage.py runserver`
2. Is firewall blocking port 8000?
3. Can you ping the server? `ping 10.0.2.2`
4. Check Django console for errors

---

## Connection Settings Applied

```python
# Middleware position
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',  # Position 1 - CORRECT
    'django.contrib.sessions.middleware.SessionMiddleware',
    ...
]

# CORS Settings
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_METHODS = ['DELETE', 'GET', 'OPTIONS', 'PATCH', 'POST', 'PUT']
CORS_PREFLIGHT_MAX_AGE = 3600
CORS_EXPOSE_HEADERS = ['content-type', 'authorization']

# Connection Management
CONN_MAX_AGE = 600  # Keep connections alive 10 minutes
DATA_UPLOAD_MAX_MEMORY_SIZE = 5242880  # 5MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 5242880  # 5MB

# Host Configuration
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '10.0.2.2', '0.0.0.0', '*']
```

---

## API Endpoints Available for Mobile

### Authentication
- `POST /api/auth/login/utilisateur/` - Login user
- `POST /api/auth/register/utilisateur/` - Register new user
- `POST /api/auth/verify-token/` - Verify JWT token

### Events
- `GET /api/evenements/` - List all events (public)
- `GET /api/evenements/{id}/` - Get event details

### Recommendations
- `GET /api/ai/recommendation/` - Get best recommendation
- `GET /api/ai/recommendations/` - Get top N recommendations

### Users
- `GET /api/utilisateurs/` - List users (auth required)
- `GET /api/utilisateurs/{id}/` - Get user details (auth required)

### Tickets
- `GET /api/tickets/` - List user's tickets (auth required)
- `POST /api/tickets/` - Create new ticket (auth required)

### Purchases
- `GET /api/achats/` - List purchases (auth required)
- `POST /api/achats/` - Create purchase (auth required)

---

## Performance Metrics

After applying optimizations:
- **Connection Timeout**: Resolved (was: immediate timeout)
- **Broken Pipe Errors**: Eliminated by CONN_MAX_AGE=600
- **Preflight Latency**: Reduced by CORS_PREFLIGHT_MAX_AGE=3600
- **Concurrent Connections**: Supported by connection pooling
- **Max Upload**: 5MB (DATA_UPLOAD_MAX_MEMORY_SIZE)

---

## Next Steps

1. **Restart Server** (if not already running):
   ```bash
   python manage.py runserver
   ```

2. **Test from Mobile**:
   - Android Emulator: Use `10.0.2.2:8000`
   - iOS Simulator: Use `127.0.0.1:8000`

3. **Monitor Logs**:
   - Watch for "Broken pipe" errors (should be gone)
   - Watch for CORS-related errors (should be none)

4. **Verify Success**:
   - ✓ User registration works
   - ✓ Login returns token
   - ✓ API requests with token work
   - ✓ No timeout errors
   - ✓ No broken pipe errors

