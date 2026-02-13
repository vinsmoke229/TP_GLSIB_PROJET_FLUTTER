"""
AI Recommendation API Endpoints

Provides endpoints for personalized event recommendations.
"""

from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.status import HTTP_200_OK, HTTP_400_BAD_REQUEST
from rest_framework.permissions import IsAuthenticated
from rest_framework.viewsets import ViewSet

from tickets.utils.ai_engine import get_personalized_recommendation, get_top_recommendations
from tickets.models.utilisateurs import Utilisateur


class RecommendationViewSet(ViewSet):
    """
    Endpoints for AI-powered event recommendations.
    
    Actions:
    - GET /api/ai/recommend/ - Get single personalized recommendation (alias)
    - GET /api/ai/recommendation/ - Get single personalized recommendation
    - GET /api/ai/recommendations/ - Get top 5 recommendations
    """
    
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['GET'], url_path='recommend')
    def recommend(self, request):
        """
        Get a single personalized event recommendation (alias endpoint).
        
        Returns:
            {
                "event_id": 1,
                "titre": "Event Name",
                "type": "Music",
                "date": "2026-02-20",
                "lieu": "Venue",
                "image": "url",
                "latitude": 6.1311,
                "longitude": 1.2132,
                "reason": "La raison de la recommandation",
                "confidence_score": 0.95,
                "matched_interests": ["Music"]
            }
        """
        return self.get_recommendation(request)
    
    @action(detail=False, methods=['GET'], url_path='recommendation')
    def get_recommendation(self, request):
        """
        Get a single personalized event recommendation.
        
        Returns:
            {
                "event_id": 1,
                "titre": "Event Name",
                "type": "Music",
                "date": "2026-02-20",
                "lieu": "Venue",
                "image": "url",
                "latitude": 6.1311,
                "longitude": 1.2132,
                "reason": "La raison de la recommandation",
                "confidence_score": 0.95,
                "matched_interests": ["Music"]
            }
        """
        try:
            user = request.user
            
            # Get recommendation
            recommendation = get_personalized_recommendation(user)
            
            if not recommendation:
                return Response(
                    {"error": "No upcoming events available"},
                    status=HTTP_400_BAD_REQUEST
                )
            
            return Response(recommendation, status=HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {"error": f"Recommendation error: {str(e)}"},
                status=HTTP_400_BAD_REQUEST
            )
    
    @action(detail=False, methods=['GET'], url_path='recommendations')
    def get_recommendations(self, request):
        """
        Get top 5 personalized event recommendations.
        
        Query Parameters:
        - limit: Number of recommendations (default 5, max 20)
        
        Returns:
            {
                "count": 5,
                "recommendations": [
                    {
                        "event_id": 1,
                        "titre": "Event Name",
                        "type": "Music",
                        "date": "2026-02-20",
                        "lieu": "Venue",
                        "image": "url",
                        "latitude": 6.1311,
                        "longitude": 1.2132,
                        "reason": "La raison",
                        "confidence_score": 0.95,
                        "score": 0.73
                    },
                    ...
                ]
            }
        """
        try:
            user = request.user
            limit = int(request.query_params.get('limit', 5))
            
            # Validate limit
            limit = min(limit, 20)
            limit = max(limit, 1)
            
            # Get recommendations
            recommendations = get_top_recommendations(user, limit=limit)
            
            return Response({
                "count": len(recommendations),
                "recommendations": recommendations
            }, status=HTTP_200_OK)
            
        except ValueError:
            return Response(
                {"error": "Invalid limit parameter"},
                status=HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            return Response(
                {"error": f"Recommendations error: {str(e)}"},
                status=HTTP_400_BAD_REQUEST
            )
