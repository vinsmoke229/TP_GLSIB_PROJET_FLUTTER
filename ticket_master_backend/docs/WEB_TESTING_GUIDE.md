## Web Frontend Testing Guide - EventMaster Backend

**Date:** February 9, 2026  
**Status:** CORS Enabled & Ready for Web Testing  
**Backend Framework:** Django 6.0.2 + DRF 3.16.1

---

## Quick Start

### 1. Start the Django Backend

```bash
cd eventMaster_Backend
python manage.py runserver
```

Output:
```
Starting development server at http://127.0.0.1:8000/
Django version 6.0.2
```

### 2. Start Your Web Frontend

```bash
# For React (port 3000)
npm start

# For Vue (port 8080)
npm run serve

# For Next.js (port 3000)
npm run dev
```

### 3. Test Connection

Open browser console and test:
```javascript
fetch('http://127.0.0.1:8000/api/evenements/', {
  headers: {'Content-Type': 'application/json'}
})
.then(r => r.json())
.then(data => console.log('SUCCESS!', data))
```

---

## CORS Configuration

### Current Settings (Development)

```python
# In Ticket/settings.py
CORS_ALLOW_ALL_ORIGINS = True  # During DEBUG=True
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_METHODS = ['DELETE', 'GET', 'OPTIONS', 'PATCH', 'POST', 'PUT']
CORS_ALLOW_HEADERS = [
    'accept', 'accept-encoding', 'authorization', 'content-type',
    'dnt', 'origin', 'user-agent', 'x-csrftoken', 'x-requested-with'
]
```

### Supported Origins (Development)
- `http://localhost:3000` ✓
- `http://localhost:8080` ✓
- `http://127.0.0.1:3000` ✓
- `http://127.0.0.1:8080` ✓
- Any origin when `DEBUG=True` ✓

---

## API Testing Workflow

### Step 1: Register / Login

**Register New User:**
```bash
curl -X POST http://127.0.0.1:8000/api/auth/register/utilisateur/ \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Dupont",
    "prenom": "Alice",
    "email": "alice@example.com",
    "mot_de_passe": "Password123!",
    "tel": "+22892123456"
  }'
```

**Response:**
```json
{
  "user": {
    "id_utilisateur": 123,
    "nom": "Dupont",
    "prenom": "Alice",
    "email": "alice@example.com",
    "solde": 0
  },
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Or Login Existing User:**
```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/utilisateur/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "mot_de_passe": "Password123!"
  }'
```

**Save the token for authenticated requests**

### Step 2: Browse Events

**Get All Events:**
```bash
curl http://127.0.0.1:8000/api/evenements/ \
  -H "Content-Type: application/json"
```

**Get Event Details (with GPS):**
```bash
curl http://127.0.0.1:8000/api/evenements/7/ \
  -H "Content-Type: application/json"
```

**Response includes:**
```json
{
  "id_evenement": 7,
  "titre_evenement": "Concert Koffi Olomide",
  "date": "2026-02-19",
  "lieu": "Palais de Congres de Lome",
  "type_evenement": "Music",
  "latitude": 6.1311,
  "longitude": 1.2132,
  "sessions": [
    {"id_session": 1, "date_heure": "2026-02-19T10:00:00Z"},
    {"id_session": 2, "date_heure": "2026-02-19T14:00:00Z"},
    {"id_session": 3, "date_heure": "2026-02-19T20:00:00Z"}
  ],
  "is_favorite": false
}
```

**Filter by Category:**
```bash
curl "http://127.0.0.1:8000/api/evenements/?type=Music" \
  -H "Content-Type: application/json"
```

**Search:**
```bash
curl "http://127.0.0.1:8000/api/evenements/rechercher/?q=Concert" \
  -H "Content-Type: application/json"
```

### Step 3: Get AI Recommendations

**Single Recommendation:**
```bash
TOKEN="eyJ0eXAiOiJKV1QiLCJhbGc..."

curl http://127.0.0.1:8000/api/ai/recommendation/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "event_id": 7,
  "titre": "Concert Koffi Olomide",
  "type": "Music",
  "date": "2026-02-19",
  "lieu": "Palais de Congres de Lome",
  "latitude": 6.1311,
  "longitude": 1.2132,
  "reason": "Basé sur ton intérêt pour Music, tu devrais adorer!",
  "confidence_score": 0.60,
  "matched_interests": ["Music"]
}
```

**Top 5 Recommendations:**
```bash
curl "http://127.0.0.1:8000/api/ai/recommendations/?limit=5" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### Step 4: Manage Favorites

**Add Favorite:**
```bash
curl -X POST http://127.0.0.1:8000/api/favorites/toggle/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"event_id": 7}'
```

**Get Favorites:**
```bash
curl http://127.0.0.1:8000/api/favorites/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### Step 5: Purchase Tickets

**Buy Ticket:**
```bash
curl -X POST http://127.0.0.1:8000/api/achats/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id_ticket": 1,
    "quantite": 2,
    "session_id": 123
  }'
```

**Get Purchase History:**
```bash
curl http://127.0.0.1:8000/api/achats/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Validate/Use Ticket (Check-in):**
```bash
curl -X POST http://127.0.0.1:8000/api/achats/1/valider/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

---

## Test Credentials

### Pre-seeded Users

| Email | Password | Interests | Solde |
|-------|----------|-----------|-------|
| john@example.com | Password123! | Music,Tech | 500,000 |
| marie@example.com | Password123! | Art,Music | 300,000 |
| jean@example.com | Password123! | Tech,Music,Art | 750,000 |

### Admin
| Email | Password |
|-------|----------|
| admin@eventmaster.com | AdminPass123! |

---

## JavaScript/TypeScript Examples

### Fetch Wrapper (React/Vue/Next.js)

```typescript
class EventMasterAPI {
  baseURL = 'http://127.0.0.1:8000/api';
  token = localStorage.getItem('auth_token');

  async request(endpoint, options = {}) {
    const headers = {
      'Content-Type': 'application/json',
      ...options.headers,
    };
    
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      ...options,
      headers,
    });
    
    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`);
    }
    
    return response.json();
  }

  // Authentication
  async register(userData) {
    return this.request('/auth/register/utilisateur/', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  }

  async login(email, password) {
    const data = await this.request('/auth/login/utilisateur/', {
      method: 'POST',
      body: JSON.stringify({ email, mot_de_passe: password }),
    });
    localStorage.setItem('auth_token', data.token);
    this.token = data.token;
    return data;
  }

  // Events
  async getEvents(filters = {}) {
    let url = '/evenements/';
    if (filters.type) url += `?type=${filters.type}`;
    return this.request(url);
  }

  async getEventDetail(id) {
    return this.request(`/evenements/${id}/`);
  }

  async searchEvents(query) {
    return this.request(`/evenements/rechercher/?q=${query}`);
  }

  // AI Recommendations
  async getRecommendation() {
    return this.request('/ai/recommendation/');
  }

  async getRecommendations(limit = 5) {
    return this.request(`/ai/recommendations/?limit=${limit}`);
  }

  // Favorites
  async toggleFavorite(eventId) {
    return this.request('/favorites/toggle/', {
      method: 'POST',
      body: JSON.stringify({ event_id: eventId }),
    });
  }

  // Purchases
  async buyTicket(ticketId, quantity, sessionId) {
    return this.request('/achats/', {
      method: 'POST',
      body: JSON.stringify({
        id_ticket: ticketId,
        quantite: quantity,
        session_id: sessionId,
      }),
    });
  }
}
```

### React Example

```jsx
import { useState, useEffect } from 'react';

function EventsPage() {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const api = new EventMasterAPI();

  useEffect(() => {
    api.getEvents()
      .then(data => setEvents(data.results))
      .catch(err => console.error('Error:', err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      {events.map(event => (
        <div key={event.id_evenement}>
          <h3>{event.titre_evenement}</h3>
          <p>Location: ({event.latitude}, {event.longitude})</p>
          <button onClick={() => api.toggleFavorite(event.id_evenement)}>
            Add to Favorites
          </button>
        </div>
      ))}
    </div>
  );
}
```

---

## Debugging CORS Issues

### If You Get CORS Error

1. **Check Backend is Running**
   ```bash
   curl http://127.0.0.1:8000/api/evenements/
   ```

2. **Verify CORS Headers in Response**
   ```bash
   curl -i http://127.0.0.1:8000/api/evenements/
   ```
   
   Look for:
   ```
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
   Access-Control-Allow-Headers: ...
   ```

3. **Check Browser Console**
   - Look for specific CORS error messages
   - Check `Network` tab in DevTools
   - Verify `Origin` header is being sent

4. **Test with Postman**
   ```
   No CORS issues with Postman (it bypasses CORS)
   If it works in Postman but not browser, it's a frontend setup issue
   ```

---

## Production Deployment

When deploying to production, update `settings.py`:

```python
# Production CORS settings
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = [
    "https://eventmaster.com",
    "https://www.eventmaster.com",
    "https://app.eventmaster.com",
]
```

Also update Django settings:
```python
DEBUG = False
ALLOWED_HOSTS = ['eventmaster.com', 'www.eventmaster.com']
```

---

## Environment Variables Needed

If using environment variables (recommended):

```bash
# .env file
DEBUG=True
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-key
GEMINI_API_KEY=your-gemini-key  # Optional
USE_DOCKER=False
DB_ENGINE=django.db.backends.sqlite3
DB_NAME=db.sqlite3
```

---

## Troubleshooting Checklist

- [ ] Django server running on localhost:8000
- [ ] Frontend running on localhost:3000 or 8080  
- [ ] No errors in Django console
- [ ] No CORS errors in browser console
- [ ] Token is saved after login
- [ ] Token is sent in Authorization header
- [ ] API endpoints respond with 200 status
- [ ] GPS coordinates visible in event details
- [ ] Recommendations working when authenticated

---

## Performance Tips for Web Development

1. **Use Pagination**
   ```javascript
   // Events list is paginated by default (10 items per page)
   fetch('http://127.0.0.1:8000/api/evenements/?page=2')
   ```

2. **Filter Early**
   ```javascript
   // Filter by type instead of getting all events
   fetch('http://127.0.0.1:8000/api/evenements/?type=Music')
   ```

3. **Cache Tokens**
   ```javascript
   localStorage.setItem('auth_token', token)
   ```

4. **Handle Errors Gracefully**
   ```javascript
   try {
     const data = await api.getEvents();
   } catch (error) {
     console.error('Failed to fetch events:', error);
   }
   ```

---

## Support

For issues or questions:
1. Check Django console for errors
2. Review CORS configuration in settings.py
3. Test with curl before testing in browser
4. Check browser DevTools Network tab
5. Verify all credentials are correct
