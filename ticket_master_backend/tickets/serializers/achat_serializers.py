from rest_framework import serializers
from ..models.achat import Achat
from ..models.utilisateurs import Utilisateur
from ..models.ticket import Ticket
from .utilisateur_serializers import UtilisateurListSerializer
from .ticket_serializers import TicketListSerializer


class AchatSerializer(serializers.ModelSerializer):
    utilisateur_details = UtilisateurListSerializer(source='id_utilisateur', read_only=True)
    ticket_details = TicketListSerializer(source='id_ticket', read_only=True)
    qr_code_url = serializers.SerializerMethodField()
    
    def get_qr_code_url(self, obj):
        """Retourner l'URL absolue du QR code"""
        request = self.context.get('request')
        if obj.qr_image and request:
            return request.build_absolute_uri(obj.qr_image.url)
        elif obj.qr_image:
            return obj.qr_image.url
        return None
    
    class Meta:
        model = Achat
        fields = [
            'id_achat', 'id_utilisateur', 'id_ticket', 'quantite', 'montant_total', 'date_achat',
            'utilisateur_details', 'ticket_details', 'est_utilise', 'code_qr', 'qr_image', 'qr_code_url', 'date_utilisation'
        ]
        read_only_fields = ['id_achat', 'montant_total', 'date_achat', 'est_utilise', 'code_qr', 'qr_image', 'date_utilisation']


class AchatCreateSerializer(serializers.ModelSerializer):
    """Serializer pour la création d'achats - L'utilisateur est automatiquement défini depuis le JWT"""
    class Meta:
        model = Achat
        fields = ['id_ticket', 'quantite']  # id_utilisateur removed - set from request.user
        extra_kwargs = {
            'quantite': {'min_value': 1, 'default': 1}
        }
    
    def validate_id_ticket(self, value):
        try:
            Ticket.objects.get(id_ticket=value.id_ticket)
        except Ticket.DoesNotExist:
            raise serializers.ValidationError("Le ticket spécifié n'existe pas.")
        return value
    
    def validate_quantite(self, value):
        if value < 1:
            raise serializers.ValidationError("La quantité doit être supérieure à 0.")
        return value
    
    def validate(self, data):
        """Validation globale - vérifier le stock et le solde disponible"""
        ticket = data['id_ticket']
        # Get user from JWT token context
        utilisateur = self.context['request'].user
        quantite = data.get('quantite', 1)
        
        # Vérifier que l'utilisateur est actif
        if utilisateur.statut != 'actif':
            raise serializers.ValidationError({
                'utilisateur': "Votre compte est inactif. Veuillez contacter l'administrateur."
            })
        
        # Vérifier le stock disponible
        if ticket.stock < quantite:
            raise serializers.ValidationError({
                'quantite': f'Stock insuffisant. Seulement {ticket.stock} ticket(s) disponible(s).'
            })
        
        # Vérifier que l'utilisateur a assez de solde
        montant_total = ticket.prix * quantite
        if utilisateur.solde < montant_total:
            raise serializers.ValidationError({
                'solde': f'Solde insuffisant. Nécessaire: {montant_total}, Disponible: {utilisateur.solde}'
            })
        
        return data
    
    
    def create(self, validated_data):
        from django.db import transaction
        
        quantite = validated_data['quantite']
        ticket = validated_data['id_ticket']
        # Get user from JWT token context (SECURITY: prevents user ID manipulation)
        utilisateur = self.context['request'].user
        
        # Calculer le montant total
        montant_total = ticket.prix * quantite
        validated_data['montant_total'] = montant_total
        validated_data['id_utilisateur'] = utilisateur  # Set user from JWT token
        
        # CRITICAL: Wrap in atomic transaction to prevent race conditions (Bug #1 fix)
        with transaction.atomic():
            achat = Achat.objects.create(**validated_data)
            
            # Déduire le montant du solde de l'utilisateur
            utilisateur.solde -= montant_total
            utilisateur.save()
            
            # Décrémenter le stock du ticket
            ticket.stock -= quantite
            ticket.save()
        
        return achat


class AchatListSerializer(serializers.ModelSerializer):
    utilisateur_nom = serializers.CharField(source='id_utilisateur.prenom', read_only=True)
    utilisateur_prenom = serializers.CharField(source='id_utilisateur.nom', read_only=True)
    ticket_type = serializers.CharField(source='id_ticket.type', read_only=True)
    ticket_prix = serializers.DecimalField(
        source='id_ticket.prix',
        read_only=True,
        max_digits=10,
        decimal_places=2
    )
    evenement_titre = serializers.CharField(source='id_ticket.id_evenement.titre_evenement', read_only=True)
    evenement_date = serializers.DateField(source='id_ticket.id_evenement.date', read_only=True)
    evenement_lieu = serializers.CharField(source='id_ticket.id_evenement.lieu', read_only=True)
    evenement_image = serializers.CharField(source='id_ticket.id_evenement.image', read_only=True)
    qr_code_url = serializers.SerializerMethodField()
    
    def get_qr_code_url(self, obj):
        """Retourner l'URL absolue du QR code"""
        request = self.context.get('request')
        if obj.qr_image and request:
            return request.build_absolute_uri(obj.qr_image.url)
        elif obj.qr_image:
            return obj.qr_image.url
        return None
    
    class Meta:
        model = Achat
        fields = [
            'id_achat', 'date_achat', 'quantite', 'montant_total',
            'utilisateur_nom', 'utilisateur_prenom',
            'ticket_type', 'ticket_prix', 'evenement_titre', 'evenement_date', 'evenement_lieu', 'evenement_image', 
            'est_utilise', 'code_qr', 'qr_code_url', 'date_utilisation'
        ]


class AchatDetailSerializer(serializers.ModelSerializer):
    """Serializer détaillé pour un achat spécifique - Structure HYBRIDE (Flat Keys + Nested Objects)"""
    # Flat keys for Mobile compatibility
    utilisateur_nom = serializers.CharField(source='id_utilisateur.prenom', read_only=True)
    utilisateur_prenom = serializers.CharField(source='id_utilisateur.nom', read_only=True)
    ticket_type = serializers.CharField(source='id_ticket.type', read_only=True)
    ticket_prix = serializers.DecimalField(
        source='id_ticket.prix',
        read_only=True,
        max_digits=10,
        decimal_places=2
    )
    evenement_titre = serializers.CharField(source='id_ticket.id_evenement.titre_evenement', read_only=True)
    evenement_date = serializers.DateField(source='id_ticket.id_evenement.date', read_only=True)
    evenement_lieu = serializers.CharField(source='id_ticket.id_evenement.lieu', read_only=True)
    evenement_image = serializers.CharField(source='id_ticket.id_evenement.image', read_only=True)
    
    # Nested objects for Web compatibility
    utilisateur = UtilisateurListSerializer(source='id_utilisateur', read_only=True)
    ticket = TicketListSerializer(source='id_ticket', read_only=True)
    evenement = serializers.SerializerMethodField()
    qr_code_url = serializers.SerializerMethodField()
    
    def get_evenement(self, obj):
        from .evenement_serializers import EvenementListSerializer
        return EvenementListSerializer(obj.id_ticket.id_evenement).data
    
    def get_qr_code_url(self, obj):
        """Retourner l'URL absolue du QR code"""
        request = self.context.get('request')
        if obj.qr_image and request:
            return request.build_absolute_uri(obj.qr_image.url)
        elif obj.qr_image:
            return obj.qr_image.url
        return None
    
    class Meta:
        model = Achat
        fields = [
            'id_achat', 'date_achat', 'quantite', 'montant_total',
            'utilisateur_nom', 'utilisateur_prenom',
            'ticket_type', 'ticket_prix', 'evenement_titre', 'evenement_date', 'evenement_lieu', 'evenement_image', 'est_utilise',
            'utilisateur', 'ticket', 'evenement',
            'code_qr', 'qr_image', 'qr_code_url', 'date_utilisation'
        ]
        read_only_fields = ['id_achat', 'date_achat', 'montant_total', 'est_utilise', 'code_qr', 'qr_image', 'date_utilisation']


class AchatStatistiquesSerializer(serializers.Serializer):
    """Serializer pour les statistiques d'achats"""
    total_achats = serializers.IntegerField()
    total_tickets_vendus = serializers.IntegerField()
    total_revenus = serializers.DecimalField(max_digits=10, decimal_places=2)
    ticket_plus_vendu = serializers.CharField()
    evenement_plus_populaire = serializers.CharField()