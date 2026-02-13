from rest_framework import serializers
from ..models.transaction import Transaction
from ..models.utilisateurs import Utilisateur
from decimal import Decimal

class TransactionSerializer(serializers.ModelSerializer):
    utilisateur_nom = serializers.CharField(source='id_utilisateur.nom', read_only=True)
    utilisateur_prenom = serializers.CharField(source='id_utilisateur.prenom', read_only=True)
    type_transaction_display = serializers.CharField(source='get_type_transaction_display', read_only=True)
    moyen_paiement_display = serializers.CharField(source='get_moyen_paiement_display', read_only=True)
    
    class Meta:
        model = Transaction
        fields = [
            'id_transaction', 'id_utilisateur', 'utilisateur_nom', 
            'utilisateur_prenom', 'montant', 'date_transaction', 
            'type_transaction', 'type_transaction_display', 'reference', 
             'id_achat', 'moyen_paiement', 'moyen_paiement_display'
        ]
        read_only_fields = ['id_transaction', 'date_transaction', 'reference']


class TransactionListSerializer(serializers.ModelSerializer):
    """Serializer simplifié pour lister les transactions"""
    utilisateur = serializers.SerializerMethodField()
    type_display = serializers.CharField(source='get_type_transaction_display', read_only=True)
    signe = serializers.SerializerMethodField()
    
    class Meta:
        model = Transaction
        fields = [
            'id_transaction', 'utilisateur', 'montant', 'signe',
            'date_transaction', 'type_transaction', 'type_display', 
            'reference'
        ]
    
    def get_utilisateur(self, obj):
        return f"{obj.id_utilisateur.prenom} {obj.id_utilisateur.nom}"
    
    def get_signe(self, obj):
        return "+" if obj.type_transaction in ['depot', 'remboursement', 'bonus_parrainage'] else "-"


class DepotSerializer(serializers.Serializer):
    """Serializer pour effectuer un dépôt"""
    montant = serializers.DecimalField(max_digits=10, decimal_places=2)
    moyen_paiement = serializers.ChoiceField(
        choices=['mobile_money', 'carte_bancaire', 'virement', 'especes'],
        help_text="Mode de paiement"
    )
    description = serializers.CharField(required=False, allow_blank=True)
    
    def validate_montant(self, value):
        if value <= 0:
            raise serializers.ValidationError("Le montant doit être supérieur à 0.")
        if value < Decimal('500'):
            raise serializers.ValidationError("Le montant minimum de dépôt est de 500 FCFA.")
        if value > Decimal('1000000'):
            raise serializers.ValidationError("Le montant maximum de dépôt est de 1 000 000 FCFA.")
        return value


class TransactionDetailSerializer(serializers.ModelSerializer):
    """Serializer détaillé pour une transaction spécifique"""
    utilisateur = serializers.SerializerMethodField()
    type_display = serializers.CharField(source='get_type_transaction_display', read_only=True)
    moyen_paiement_display = serializers.CharField(source='get_moyen_paiement_display', read_only=True)
    achat_details = serializers.SerializerMethodField()
    
    class Meta:
        model = Transaction
        fields = [
            'id_transaction', 'utilisateur', 'montant', 
            'date_transaction', 'type_transaction', 'type_display',
            'reference', 'moyen_paiement', 
            'moyen_paiement_display', 'achat_details'
        ]
    
    def get_utilisateur(self, obj):
        return {
            'id': obj.id_utilisateur.id_utilisateur,
            'nom_complet': f"{obj.id_utilisateur.prenom} {obj.id_utilisateur.nom}",
            'email': obj.id_utilisateur.email
        }
    
    def get_achat_details(self, obj):
        if obj.id_achat:
            return {
                'id_achat': obj.id_achat.id_achat,
                'quantite': obj.id_achat.quantite,
                'ticket_type': obj.id_achat.id_ticket.type,
                'code_qr': obj.id_achat.code_qr
            }
        return None