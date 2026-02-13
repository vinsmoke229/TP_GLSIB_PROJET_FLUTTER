"""
AI Recommendation Routes

Routes:
- GET /api/ai/recommendation/ - Single personalized recommendation
- GET /api/ai/recommendations/ - Top N recommendations
"""

from rest_framework.routers import DefaultRouter
from tickets.views.gestion_ai_recommendations import RecommendationViewSet

router = DefaultRouter()
router.register(r'', RecommendationViewSet, basename='ai-recommendation')

app_name = 'ai_recommendations'
urlpatterns = router.urls
