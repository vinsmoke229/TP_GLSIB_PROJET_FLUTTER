from rest_framework import serializers
from ..models.favori import Favori
from ..models.evenements import Evenement
from .evenement_serializers import EvenementListSerializer


class FavoriSerializer(serializers.ModelSerializer):
    """Serializer pour les favoris - Réponse simple avec statut toggle"""
    
    class Meta:
        model = Favori
        fields = ['id_favori', 'utilisateur', 'evenement', 'date_ajout']
        read_only_fields = ['id_favori', 'utilisateur', 'date_ajout']


class FavoriDetailSerializer(serializers.ModelSerializer):
    """Serializer détaillé pour afficher un favori avec les infos de l'événement"""
    evenement_details = EvenementListSerializer(source='evenement', read_only=True)
    
    class Meta:
        model = Favori
        fields = ['id_favori', 'date_ajout', 'evenement_details']
        read_only_fields = ['id_favori', 'date_ajout']


class FavoriListSerializer(serializers.ModelSerializer):
    """Serializer pour lister les favoris d'un utilisateur"""
    id_evenement = serializers.IntegerField(source='evenement.id_evenement', read_only=True)
    titre_evenement = serializers.CharField(source='evenement.titre_evenement', read_only=True)
    date = serializers.DateField(source='evenement.date', read_only=True)
    lieu = serializers.CharField(source='evenement.lieu', read_only=True)
    image = serializers.CharField(source='evenement.image', read_only=True)
    type_evenement = serializers.CharField(source='evenement.type_evenement', read_only=True)
    
    class Meta:
        model = Favori
        fields = ['id_favori', 'id_evenement', 'titre_evenement', 'date', 'lieu', 'image', 'type_evenement', 'date_ajout']
        read_only_fields = ['id_favori', 'date_ajout']
