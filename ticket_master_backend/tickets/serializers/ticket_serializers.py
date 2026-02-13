from rest_framework import serializers
from ..models.ticket import Ticket
from ..models.evenements import Evenement
from .evenement_serializers import EvenementSerializer


class TicketSerializer(serializers.ModelSerializer):
    """Serializer pour le modèle Ticket"""
    evenement_details = EvenementSerializer(source='id_evenement', read_only=True)
    
    class Meta:
        model = Ticket
        fields = ['id_ticket', 'type', 'prix', 'date_creation', 'stock', 'id_evenement', 'evenement_details']
        read_only_fields = ['id_ticket', 'date_creation']
    
    def validate_prix(self, value):
        if value <= 0:
            raise serializers.ValidationError("Le prix doit être supérieur à 0.")
        return value
    
    def validate_stock(self, value):
        if value < 0:
            raise serializers.ValidationError("Le stock ne peut pas être négatif.")
        return value
    
    def validate_id_evenement(self, value):
        if not Evenement.objects.filter(id_evenement=value.id_evenement).exists():
            raise serializers.ValidationError("L'événement spécifié n'existe pas.")
        return value


class TicketCreateSerializer(serializers.ModelSerializer):
    """Serializer spécifique pour la création de tickets"""
    class Meta:
        model = Ticket
        fields = ['type', 'prix', 'stock', 'id_evenement']
    
    def validate(self, data):
        """Validation globale"""
        if data['prix'] <= 0:
            raise serializers.ValidationError({"prix": "Le prix doit être supérieur à 0."})
        if data['stock'] < 0:
            raise serializers.ValidationError({"stock": "Le stock ne peut pas être négatif."})
        return data


class TicketUpdateSerializer(serializers.ModelSerializer):
    """Serializer spécifique pour la mise à jour de tickets"""
    class Meta:
        model = Ticket
        fields = ['type', 'prix', 'stock']
        extra_kwargs = {
            'type': {'required': False},
            'prix': {'required': False},
            'stock': {'required': False},
        }


class TicketListSerializer(serializers.ModelSerializer):
    """Serializer simplifié pour lister les tickets"""
    evenement_nom = serializers.CharField(source='id_evenement.titre_evenement', read_only=True)
    
    class Meta:
        model = Ticket
        fields = ['id_ticket', 'type', 'prix', 'stock', 'date_creation', 'evenement_nom','id_evenement']