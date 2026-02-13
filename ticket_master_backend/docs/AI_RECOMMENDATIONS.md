## AI Recommendation Engine Documentation

### Overview

EventMaster now includes an intelligent AI-powered recommendation engine that:
- Analyzes user interests (Music, Tech, Art, etc.)
- Tracks user purchase history
- Scores events based on relevance
- Uses Google Gemini API for personalized justifications (optional)
- Falls back to smart defaults when no API key is configured

---

## Installation & Configuration

### 1. Python Package

The `google-generativeai` package is already installed:
```bash
pip install google-generativeai
```

### 2. Environment Configuration (Optional - for Gemini API)

To enable Gemini-powered justifications, add to your `.env`:
```env
GEMINI_API_KEY=your_api_key_here
```

Without this key, the system uses intelligent fallback justifications.

---

## API Endpoints

### Base URL
```
/api/ai/
```

### 1. Single Personalized Recommendation

**Endpoint:** `GET /api/ai/recommendation/`

**Authentication:** Required (Bearer Token)

**Description:** Returns the single best event recommendation for the authenticated user.

**Example Request:**
```bash
curl -X GET http://localhost:8000/api/ai/recommendation/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
```

**Example Response:**
```json
{
  "event_id": 7,
  "titre": "Concert Koffi Olomide",
  "type": "Music",
  "date": "2026-02-19",
  "lieu": "Palais de Congres de Lome",
  "image": "https://via.placeholder.com/400x300?text=Concert",
  "latitude": 6.1311,
  "longitude": 1.2132,
  "reason": "Basé sur ton intérêt pour Music, tu devrais adorer!",
  "confidence_score": 0.60,
  "matched_interests": ["Music"]
}
```

**Response Fields:**
| Field | Type | Description |
|-------|------|-------------|
| event_id | int | Unique event identifier |
| titre | string | Event name |
| type | string | Event category (Music, Tech, Art) |
| date | string | Event date (ISO 8601) |
| lieu | string | Event location |
| image | string | Event image URL |
| latitude | float | GPS latitude coordinate |
| longitude | float | GPS longitude coordinate |
| reason | string | Personalized explanation for recommendation |
| confidence_score | float | Recommendation confidence (0.0-1.0) |
| matched_interests | list | User interests matching event type |

---

### 2. Top N Recommendations

**Endpoint:** `GET /api/ai/recommendations/`

**Authentication:** Required (Bearer Token)

**Query Parameters:**
- `limit` (optional, default=5, max=20): Number of recommendations

**Description:** Returns top N event recommendations sorted by relevance score.

**Example Request:**
```bash
curl -X GET "http://localhost:8000/api/ai/recommendations/?limit=3" \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
```

**Example Response:**
```json
{
  "count": 3,
  "recommendations": [
    {
      "event_id": 7,
      "titre": "Concert Koffi Olomide",
      "type": "Music",
      "date": "2026-02-19",
      "lieu": "Palais de Congres de Lome",
      "image": "https://via.placeholder.com/400x300?text=Concert",
      "latitude": 6.1311,
      "longitude": 1.2132,
      "reason": "Basé sur ton intérêt pour Music, tu devrais adorer!",
      "confidence_score": 0.60,
      "score": 0.50
    },
    {
      "event_id": 9,
      "titre": "Conference Tech Africa",
      "type": "Tech",
      "date": "2026-03-11",
      "lieu": "Hotel Meridien Lome",
      "image": "https://via.placeholder.com/400x300?text=Tech+Conference",
      "latitude": 6.1284,
      "longitude": 1.2592,
      "reason": "Basé sur ton intérêt pour Tech, tu devrais adorer!",
      "confidence_score": 0.60,
      "score": 0.50
    },
    {
      "event_id": 8,
      "titre": "Festival Culturel 2026",
      "type": "Art",
      "date": "2026-03-06",
      "lieu": "Stade de Lome",
      "image": "https://via.placeholder.com/400x300?text=Festival+Culturel",
      "latitude": 6.1834,
      "longitude": 1.2334,
      "reason": "Un superbe événement Art très populaire en ce moment.",
      "confidence_score": 0.20,
      "score": 0.10
    }
  ]
}
```

**Response Fields:**
| Field | Type | Description |
|-------|------|-------------|
| count | int | Number of recommendations returned |
| recommendations | array | Array of recommendation objects |
| [].score | float | Internal relevance score (0.0-1.0) |
| [].confidence_score | float | User-facing confidence (0.0-1.0) |

---

## Recommendation Algorithm

### Scoring Mechanism

The recommendation engine uses a **multi-factor scoring system**:

#### 1. Interest Match Score (0.0-0.5)
- **Direct match** with user interests: +0.5
- **User has interests but no match**: +0.1
- **User has no interests specified**: +0.1

#### 2. Purchase History Score (0.0-0.3)
- Based on previous ticket purchases by category
- Each past purchase type: +0.15 (capped at 0.3)

#### 3. Popularity Score (0.0-0.2)
- Based on total tickets sold for each event
- Formula: min(0.2, sales_count * 0.01)

#### 4. Confidence Score
- Combined score from above: `score + 0.1`
- Normalized to 0.0-1.0 range

### Example Calculation

```
User: John Doe
Interests: Music, Tech
Past Purchases: Music (2x), Tech (1x)

Event: Concert Koffi Olomide (Music)
  - Interest Match: 0.5 (direct Music match)
  - Purchase History: 0.3 (2 past Music purchases * 0.15)
  - Popularity: 0.02 (10 sales * 0.01)
  - Total Score: 0.82
  - Confidence: 0.92 (0.82 + 0.1)

Event: Festival Culturel (Art)
  - Interest Match: 0.1 (no Art interest, but user has interests)
  - Purchase History: 0.0 (no Art purchases)
  - Popularity: 0.01 (1 sale * 0.01)
  - Total Score: 0.11
  - Confidence: 0.21 (0.11 + 0.1)
```

---

## User Interests Management

### Setting User Interests

Interests are stored as **comma-separated strings** in the `Utilisateur.interests` field.

**Example:**
```python
from tickets.models.utilisateurs import Utilisateur

user = Utilisateur.objects.get(id_utilisateur=1)
user.interests = "Music,Tech,Art"
user.save()
```

**Valid Interest Types:**
- `Music` - Concert, music festivals
- `Tech` - Technology conferences, tech talks
- `Art` - Art exhibitions, cultural festivals
- Custom categories supported

---

## Gemini Integration

### How It Works

When `GEMINI_API_KEY` is set:

1. **Initialization:**
   ```python
   genai.configure(api_key=GEMINI_API_KEY)
   ```

2. **Prompt Template:**
   ```
   Génère une justification courte (1 phrase max, 10-15 mots) pour recommander cet événement à un utilisateur.
   
   Event: {titre_evenement}
   Type: {type_evenement}
   Lieu: {lieu}
   User Interests: {interests}
   Confidence Score: {confidence:.2%}
   ```

3. **Gemini Response:**
   - Generates personalized 1-sentence justification
   - Language: French (localizable)
   - Max 50 tokens
   - Temperature: 0.7 (balanced creativity)

### Fallback System

Without Gemini API, the system uses intelligent fallbacks:

```python
# Direct interest match
"Basé sur ton intérêt pour Music, tu devrais adorer!"

# No interest match, but populated interests
"Un superbe événement Tech très populaire en ce moment."

# No interests specified
"Un événement à ne pas manquer!"
```

---

## Code Architecture

### Files

| File | Purpose |
|------|---------|
| `tickets/utils/ai_engine.py` | Core recommendation logic |
| `tickets/views/gestion_ai_recommendations.py` | API view endpoints |
| `tickets/urls/ai_urls.py` | URL routing |
| `tickets/models/utilisateurs.py` | User model (with interests field) |

### Key Functions

#### `get_personalized_recommendation(user: Utilisateur)`
Returns single best recommendation for user.

```python
from tickets.utils.ai_engine import get_personalized_recommendation
from tickets.models.utilisateurs import Utilisateur

user = Utilisateur.objects.get(id_utilisateur=1)
rec = get_personalized_recommendation(user)
if rec:
    print(f"Recommended: {rec['titre']}")
```

#### `get_top_recommendations(user: Utilisateur, limit: int = 5)`
Returns top N recommendations.

```python
from tickets.utils.ai_engine import get_top_recommendations

recommendations = get_top_recommendations(user, limit=3)
for rec in recommendations:
    print(f"{rec['titre']} - Score: {rec['score']:.2f}")
```

#### `parse_user_interests(interests_str: str) -> List[str]`
Parses comma-separated interests.

```python
interests = parse_user_interests("Music,Tech,Art")
# Result: ['Music', 'Tech', 'Art']
```

#### `score_event_match(...)`
Calculates match score for event-user pair.

---

## Testing

### Test Coverage

✅ Single recommendation endpoint works  
✅ Multiple recommendations endpoint returns top N  
✅ Authentication required (returns 401 without token)  
✅ User interests properly matched  
✅ Fallback justifications generated  
✅ GPS coordinates included  
✅ Event dates and details accurate  

### Manual Testing

```bash
# Login and get token
curl -X POST http://localhost:8000/api/auth/login/utilisateur/ \
  -d "email=john@example.com&mot_de_passe=Password123!"

# Get recommendation
curl -X GET http://localhost:8000/api/ai/recommendation/ \
  -H "Authorization: Bearer $TOKEN"

# Get top 5 recommendations
curl -X GET "http://localhost:8000/api/ai/recommendations/?limit=5" \
  -H "Authorization: Bearer $TOKEN"
```

---

## Error Handling

### Possible Errors

| Status | Error | Cause |
|--------|-------|-------|
| 401 | No token | Missing Authentication header |
| 400 | Invalid limit | `limit` parameter not numeric or out of range |
| 400 | No upcoming events | Database has no future events |
| 500 | Recommendation error | Exception in recommendation logic |

### Error Response Format

```json
{
  "error": "No upcoming events available"
}
```

---

## Performance Considerations

### Database Queries

- **Single Recommendation:** ~5 queries
  - Get user
  - Get upcoming events
  - Get user purchase history (aggregated)
  - Calculate event sales counts (per-event)

- **Multiple Recommendations:** O(n) where n = number of upcoming events
  - Efficient use of `annotate()` and `select_related()`

### Caching Recommendations

For high-traffic deployments, consider caching:

```python
from django.core.cache import cache

def get_cached_recommendation(user_id, timeout=3600):
    key = f"rec:{user_id}"
    rec = cache.get(key)
    if not rec:
        user = Utilisateur.objects.get(id_utilisateur=user_id)
        rec = get_personalized_recommendation(user)
        cache.set(key, rec, timeout)
    return rec
```

---

## Future Enhancements

### Planned Features

1. **Collaborative Filtering**
   - Recommendations based on similar users
   - "Users like you also purchased..."

2. **Temporal Factors**
   - Boost events happening soon
   - Seasonal event preferences

3. **Location-Based**
   - Recommend nearby events using GPS
   - Distance-weighted scoring

4. **Advanced NLP**
   - Extract interests from user reviews
   - Sentiment analysis on event descriptions

5. **A/B Testing**
   - Track recommendation acceptance rate
   - Optimize scoring weights

---

## Database Schema

### Utilisateur Model

```python
class Utilisateur(models.Model):
    id_utilisateur = AutoField(primary_key=True)
    nom = CharField(max_length=100)
    prenom = CharField(max_length=100)
    email = EmailField(unique=True)
    interests = TextField(blank=True, default='')  # NEW
    solde = DecimalField(max_digits=10, decimal_places=2)
    # ... other fields
```

### Migration

```
tickets/migrations/0008_utilisateur_interests.py
- Adds TextField for comma-separated interests
- Default value: empty string
- Supports null=True for flexibility
```

---

## Integration with Mobile App

### Flutter Implementation Example

```dart
class AIRecommendationService {
  final String baseUrl = "http://api.eventmaster.com";
  
  Future<Map<String, dynamic>> getRecommendation(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/ai/recommendation/"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    return jsonDecode(response.body);
  }
  
  Future<List<Map>> getTopRecommendations(String token, {int limit = 5}) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/ai/recommendations/?limit=$limit"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    final data = jsonDecode(response.body);
    return List<Map>.from(data['recommendations']);
  }
}
```

---

## Support

For issues or questions:
1. Check API logs: `python manage.py runserver`
2. Verify user interests: `Utilisateur.objects.filter(id_utilisateur=X).values('interests')`
3. Test recommendation logic directly: `get_personalized_recommendation(user)`
4. Check Gemini API status (if enabled): Verify API key in environment
