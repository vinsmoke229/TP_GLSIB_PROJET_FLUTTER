"""
AI Recommendation Engine for Event Master

This module provides intelligent event recommendations based on user interests
and purchase history. It integrates with Google Generative AI (Gemini) for
generating personalized justifications.
"""

import os
import logging
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Optional, Dict, Any, List

import google.generativeai as genai
from django.db.models import Count, Q
from django.utils import timezone

from tickets.models.evenements import Evenement
from tickets.models.achat import Achat
from tickets.models.utilisateurs import Utilisateur

logger = logging.getLogger(__name__)

# Configure Gemini API
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    GEMINI_AVAILABLE = True
else:
    GEMINI_AVAILABLE = False
    logger.warning("GEMINI_API_KEY not configured. Using fallback recommendations.")


def parse_user_interests(interests_str: str) -> List[str]:
    """
    Parse comma-separated interests from user model.
    
    Args:
        interests_str: Comma-separated string of interests
        
    Returns:
        List of cleaned interest strings
    """
    if not interests_str:
        return []
    return [interest.strip() for interest in interests_str.split(',') if interest.strip()]


def get_user_purchase_history(user: Utilisateur) -> Dict[str, int]:
    """
    Analyze user's purchase history to determine preferred event types.
    
    Args:
        user: Utilisateur instance
        
    Returns:
        Dictionary mapping event types to purchase count
    """
    purchases = Achat.objects.filter(
        id_utilisateur=user
    ).select_related('id_ticket__id_evenement').values(
        'id_ticket__id_evenement__type_evenement'
    ).annotate(count=Count('id_achat'))
    
    history = {}
    for purchase in purchases:
        event_type = purchase['id_ticket__id_evenement__type_evenement']
        history[event_type] = purchase['count']
    
    return history


def get_upcoming_events(days_ahead: int = 90) -> List[Evenement]:
    """
    Get upcoming events within specified days.
    
    Args:
        days_ahead: Number of days to look ahead (default 90 days)
        
    Returns:
        Queryset of upcoming Evenement objects
    """
    today = timezone.now().date()
    future_date = today + timedelta(days=days_ahead)
    
    return Evenement.objects.filter(
        date__gte=today,
        date__lte=future_date
    ).order_by('date')


def score_event_match(
    event: Evenement,
    user_interests: List[str],
    purchase_history: Dict[str, int],
    event_sales: Dict[int, int]
) -> float:
    """
    Calculate a match score between user interests and event.
    
    Score factors:
    - Interest match (0.0-0.5): Direct match with user interests
    - Purchase history (0.0-0.3): Based on past purchases
    - Popularity (0.0-0.2): Based on purchase count
    
    Args:
        event: Evenement instance
        user_interests: List of user interests
        purchase_history: Dictionary of user's past purchases by type
        event_sales: Dictionary mapping event ID to sales count
        
    Returns:
        Float score between 0.0 and 1.0
    """
    score = 0.0
    
    # Interest match score (up to 0.5)
    if user_interests:
        if event.type_evenement in user_interests:
            score += 0.5
        else:
            # Partial match for similar interests
            score += 0.1
    else:
        score += 0.1  # Neutral score if no interests specified
    
    # Purchase history score (up to 0.3)
    if event.type_evenement in purchase_history:
        purchase_count = purchase_history[event.type_evenement]
        score += min(0.3, purchase_count * 0.15)
    
    # Popularity score (up to 0.2)
    sales = event_sales.get(event.id_evenement, 0)
    if sales > 0:
        score += min(0.2, sales * 0.01)
    
    return min(1.0, score)


def get_event_sales_count(event_id: int) -> int:
    """
    Get total number of tickets sold for an event.
    
    Args:
        event_id: Event ID
        
    Returns:
        Total tickets sold
    """
    return Achat.objects.filter(
        id_ticket__id_evenement_id=event_id
    ).aggregate(
        total=Count('id_achat')
    )['total'] or 0


def generate_gemini_justification(
    user: Utilisateur,
    event: Evenement,
    confidence: float
) -> str:
    """
    Generate a personalized justification using Gemini.
    
    Args:
        user: Utilisateur instance
        event: Evenement instance
        confidence: Confidence score (0.0-1.0)
        
    Returns:
        Generated justification string
    """
    if not GEMINI_AVAILABLE:
        return get_fallback_justification(user, event, confidence)
    
    try:
        model = genai.GenerativeModel('gemini-pro')
        
        user_interests = parse_user_interests(user.interests)
        interests_text = ", ".join(user_interests) if user_interests else "général"
        
        prompt = f"""Génère une justification courte (1 phrase max, 10-15 mots) pour recommander cet événement à un utilisateur.

Event: {event.titre_evenement}
Type: {event.type_evenement}
Lieu: {event.lieu}
User Interests: {interests_text}
Confidence Score: {confidence:.2%}

Réponse en français, personnalisée et enthousiaste. Example: "Parfait pour les fans de {event.type_evenement}!"
"""
        
        response = model.generate_content(prompt, generation_config=genai.types.GenerationConfig(
            max_output_tokens=50,
            temperature=0.7
        ))
        
        justification = response.text.strip()
        # Ensure it's one sentence
        if '.' in justification:
            justification = justification.split('.')[0] + '.'
        
        return justification[:100]  # Limit to 100 chars
        
    except Exception as e:
        logger.error(f"Gemini API error: {str(e)}")
        return get_fallback_justification(user, event, confidence)


def get_fallback_justification(
    user: Utilisateur,
    event: Evenement,
    confidence: float
) -> str:
    """
    Generate a fallback justification without Gemini.
    
    Args:
        user: Utilisateur instance
        event: Evenement instance
        confidence: Confidence score
        
    Returns:
        Fallback justification string
    """
    user_interests = parse_user_interests(user.interests)
    
    if user_interests and event.type_evenement in user_interests:
        return f"Basé sur ton intérêt pour {event.type_evenement}, tu devrais adorer!"
    elif event.type_evenement:
        return f"Un superbe événement {event.type_evenement} très populaire en ce moment."
    else:
        return "Un événement à ne pas manquer!"


def get_personalized_recommendation(user: Utilisateur) -> Optional[Dict[str, Any]]:
    """
    Get personalized event recommendation for a user.
    
    Logic:
    1. Parse user interests
    2. Get purchase history
    3. Get upcoming events
    4. Score each event
    5. Select best match
    6. Generate justification
    
    Fallback: Return most popular event if no interests match
    
    Args:
        user: Utilisateur instance
        
    Returns:
        Dictionary with recommendation data or None if no events available
    """
    try:
        # Get upcoming events
        upcoming_events = get_upcoming_events()
        
        if not upcoming_events.exists():
            logger.info(f"No upcoming events found for user {user.id_utilisateur}")
            return None
        
        # Parse interests
        user_interests = parse_user_interests(user.interests)
        
        # Get purchase history
        purchase_history = get_user_purchase_history(user)
        
        # Calculate sales for each event
        event_sales = {}
        for event in upcoming_events:
            event_sales[event.id_evenement] = get_event_sales_count(event.id_evenement)
        
        # Score all events
        scored_events = []
        best_event = None
        best_score = -1
        
        for event in upcoming_events:
            score = score_event_match(
                event,
                user_interests,
                purchase_history,
                event_sales
            )
            scored_events.append((event, score))
            
            if score > best_score:
                best_score = score
                best_event = event
        
        if not best_event:
            # Fallback: Get most popular event
            best_event = max(
                upcoming_events,
                key=lambda e: event_sales.get(e.id_evenement, 0) or 0
            )
            best_score = 0.5
        
        # Normalize confidence score (0.0-1.0)
        confidence_score = min(1.0, best_score + 0.1)
        
        # Generate justification
        justification = generate_gemini_justification(
            user,
            best_event,
            confidence_score
        )
        
        return {
            "event_id": best_event.id_evenement,
            "titre": best_event.titre_evenement,
            "type": best_event.type_evenement,
            "date": best_event.date.isoformat(),
            "lieu": best_event.lieu,
            "image": best_event.image,
            "latitude": best_event.latitude,
            "longitude": best_event.longitude,
            "reason": justification,
            "confidence_score": float(confidence_score),
            "matched_interests": [i for i in user_interests if i == best_event.type_evenement]
        }
        
    except Exception as e:
        logger.error(f"Recommendation engine error for user {user.id_utilisateur}: {str(e)}", exc_info=True)
        return None


def get_top_recommendations(user: Utilisateur, limit: int = 5) -> List[Dict[str, Any]]:
    """
    Get top N event recommendations for a user.
    
    Args:
        user: Utilisateur instance
        limit: Maximum number of recommendations
        
    Returns:
        List of recommendation dictionaries
    """
    try:
        upcoming_events = get_upcoming_events()
        
        if not upcoming_events.exists():
            return []
        
        user_interests = parse_user_interests(user.interests)
        purchase_history = get_user_purchase_history(user)
        
        event_sales = {}
        for event in upcoming_events:
            event_sales[event.id_evenement] = get_event_sales_count(event.id_evenement)
        
        # Score all events
        scored_events = []
        for event in upcoming_events:
            score = score_event_match(
                event,
                user_interests,
                purchase_history,
                event_sales
            )
            scored_events.append((event, score))
        
        # Sort by score and return top N
        scored_events.sort(key=lambda x: x[1], reverse=True)
        
        recommendations = []
        for event, score in scored_events[:limit]:
            confidence_score = min(1.0, score + 0.1)
            justification = generate_gemini_justification(user, event, confidence_score)
            
            recommendations.append({
                "event_id": event.id_evenement,
                "titre": event.titre_evenement,
                "type": event.type_evenement,
                "date": event.date.isoformat(),
                "lieu": event.lieu,
                "image": event.image,
                "latitude": event.latitude,
                "longitude": event.longitude,
                "reason": justification,
                "confidence_score": float(confidence_score),
                "score": float(score)
            })
        
        return recommendations
        
    except Exception as e:
        logger.error(f"Error getting top recommendations for user {user.id_utilisateur}: {str(e)}", exc_info=True)
        return []
