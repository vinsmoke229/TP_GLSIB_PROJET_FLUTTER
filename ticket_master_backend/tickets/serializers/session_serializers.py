from rest_framework import serializers
from ..models.session import Session


class SessionSerializer(serializers.ModelSerializer):
    """Serializer pour les sessions d'événements"""
    # Explicit ISO format for Flutter compatibility (no milliseconds)
    date_heure = serializers.DateTimeField(format='%Y-%m-%dT%H:%M:%S', read_only=True)
    
    class Meta:
        model = Session
        fields = ['id_session', 'date_heure']
        read_only_fields = ['id_session']


class SessionDetailSerializer(serializers.ModelSerializer):
    """Serializer détaillé pour une session avec tous les détails"""
    # Explicit ISO format for Flutter compatibility (no milliseconds)
    date_heure = serializers.DateTimeField(format='%Y-%m-%dT%H:%M:%S', read_only=True)
    
    class Meta:
        model = Session
        fields = ['id_session', 'evenement', 'date_heure']
        read_only_fields = ['id_session']
