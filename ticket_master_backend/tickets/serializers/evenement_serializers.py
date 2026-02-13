from rest_framework import serializers
from datetime import date
from ..models.evenements import Evenement
from ..utils.geocoding import geocode_address


class EvenementSerializer(serializers.ModelSerializer):
    nombre_tickets = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()
    sessions = serializers.SerializerMethodField()
    
    class Meta:
        model = Evenement
        fields = ['id_evenement', 'titre_evenement', 'date', 'lieu', 'image', 'type_evenement', 'latitude', 'longitude', 'heure_debut', 'heure_fin', 'nombre_tickets', 'is_favorite', 'sessions']
        read_only_fields = ['id_evenement']
    
    def get_nombre_tickets(self, obj):
        """Retourner le nombre de tickets associés à cet événement"""
        return obj.ticket_set.count()
    
    def get_sessions(self, obj):
        """Retourner toutes les sessions associées à cet événement"""
        from .session_serializers import SessionSerializer
        sessions = obj.sessions.all()
        return SessionSerializer(sessions, many=True).data
    
    def get_is_favorite(self, obj):
        """Vérifier si l'utilisateur actuel a favorisé cet événement"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            from ..models.favori import Favori
            from ..models.utilisateurs import Utilisateur
            # Vérifier que c'est un utilisateur et non un administrateur
            if isinstance(request.user, Utilisateur):
                return Favori.objects.filter(utilisateur=request.user, evenement=obj).exists()
        return False
    
    def validate_titre_evenement(self, value):
        """Validation du titre de l'événement"""
        if len(value.strip()) < 3:
            raise serializers.ValidationError("Le titre doit contenir au moins 3 caractères.")
        return value.strip()
    
    def validate_date(self, value):
        """Validation de la date de l'événement"""
        if value < date.today():
            raise serializers.ValidationError("La date de l'événement ne peut pas être dans le passé.")
        return value
    
    def validate_lieu(self, value):
        """Validation du lieu"""
        if len(value.strip()) < 2:
            raise serializers.ValidationError("Le lieu doit contenir au moins 2 caractères.")
        return value.strip()
    
    def validate_image(self, value):
        """Validation du fichier image"""
        if not value:
            return value
    
        if value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError("L'image ne doit pas dépasser 5MB.")
        
    
        valid_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
        if not any(value.name.lower().endswith(ext) for ext in valid_extensions):
            raise serializers.ValidationError("Format d'image non supporté. Utilisez: jpg, jpeg, png, gif, webp")
        
        return value


class EvenementCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Evenement
        fields = ['titre_evenement', 'date', 'lieu', 'image', 'type_evenement', 'heure_debut', 'heure_fin']
    
    def validate_titre_evenement(self, value):
        if len(value.strip()) < 3:
            raise serializers.ValidationError("Le titre doit contenir au moins 3 caractères.")
        return value.strip()
    
    def validate_date(self, value):
        """Validation de la date"""
        if value < date.today():
            raise serializers.ValidationError("La date de l'événement ne peut pas être dans le passé.")
        return value
    
    def validate_lieu(self, value):
        """Validation du lieu"""
        if len(value.strip()) < 2:
            raise serializers.ValidationError("Le lieu doit contenir au moins 2 caractères.")
        return value.strip()
    
    def validate(self, data):
        """Validation globale - vérifier les doublons"""
        titre = data.get('titre_evenement')
        date_event = data.get('date')
        lieu = data.get('lieu')
        
        # Vérifier qu'il n'existe pas déjà un événement avec le même titre à la même date
        if Evenement.objects.filter(titre_evenement=titre, date=date_event).exists():
            raise serializers.ValidationError(
                "Un événement avec ce titre existe déjà à cette date."
            )
        
        return data
    
    def create(self, validated_data):
        """Créer l'événement avec géocodage automatique du lieu"""
        lieu = validated_data.get('lieu')
        
        # Géocoder l'adresse pour obtenir latitude et longitude
        if lieu:
            latitude, longitude = geocode_address(lieu)
            if latitude is not None and longitude is not None:
                validated_data['latitude'] = latitude
                validated_data['longitude'] = longitude        
        return super().create(validated_data)


class EvenementUpdateSerializer(serializers.ModelSerializer):
    """Serializer pour la mise à jour d'événements"""
    
    class Meta:
        model = Evenement
        fields = ['titre_evenement', 'date', 'lieu', 'image', 'type_evenement', 'heure_debut', 'heure_fin']
        extra_kwargs = {
            'titre_evenement': {'required': False},
            'date': {'required': False},
            'lieu': {'required': False},
            'image': {'required': False},
            'type_evenement': {'required': False},
            'heure_debut': {'required': False},
            'heure_fin': {'required': False}
        }
    
    def validate_titre_evenement(self, value):
        if value and len(value.strip()) < 3:
            raise serializers.ValidationError("Le titre doit contenir au moins 3 caractères.")
        return value.strip() if value else value
    
    def validate_date(self, value):
        if value and value < date.today():
            raise serializers.ValidationError("La date de l'événement ne peut pas être dans le passé.")
        return value
    
    def validate_lieu(self, value):
        if value and len(value.strip()) < 2:
            raise serializers.ValidationError("Le lieu doit contenir au moins 2 caractères.")
        return value.strip() if value else value
    
    def update(self, instance, validated_data):
        """Mettre à jour l'événement avec géocodage automatique si le lieu change"""
        lieu = validated_data.get('lieu')
        
        # Si le lieu change, recalculer les coordonnées GPS
        if lieu and lieu != instance.lieu:
            latitude, longitude = geocode_address(lieu)
            if latitude is not None and longitude is not None:
                validated_data['latitude'] = latitude
                validated_data['longitude'] = longitude
                print(f"✅ Géocodage réussi: {lieu} → ({latitude}, {longitude})")
            else:
                print(f"⚠️ Géocodage échoué pour: {lieu}")
        
        return super().update(instance, validated_data)


class EvenementListSerializer(serializers.ModelSerializer):
    """Serializer simplifié pour lister les événements"""
    nombre_tickets_disponibles = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()
    sessions = serializers.SerializerMethodField()
    
    class Meta:
        model = Evenement
        fields = ['id_evenement', 'titre_evenement', 'date', 'lieu', 'image', 'type_evenement', 'latitude', 'longitude', 'heure_debut', 'heure_fin', 'nombre_tickets_disponibles', 'is_favorite', 'sessions']
    
    def get_nombre_tickets_disponibles(self, obj):
        """Retourner le nombre total de tickets disponibles"""
        return sum(ticket.stock for ticket in obj.ticket_set.all())
    
    def get_sessions(self, obj):
        """Retourner toutes les sessions associées à cet événement"""
        from .session_serializers import SessionSerializer
        sessions = obj.sessions.all()
        return SessionSerializer(sessions, many=True).data
    
    def get_is_favorite(self, obj):
        """Vérifier si l'utilisateur actuel a favorisé cet événement"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            from ..models.favori import Favori
            from ..models.utilisateurs import Utilisateur
            # Vérifier que c'est un utilisateur et non un administrateur
            if isinstance(request.user, Utilisateur):
                return Favori.objects.filter(utilisateur=request.user, evenement=obj).exists()
        return False


class EvenementDetailSerializer(serializers.ModelSerializer):
    """Serializer détaillé pour un événement spécifique avec les tickets et sessions associés"""
    tickets = serializers.SerializerMethodField()
    sessions = serializers.SerializerMethodField()
    nombre_tickets_total = serializers.SerializerMethodField()
    stock_total = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()
    
    class Meta:
        model = Evenement
        fields = [
            'id_evenement', 'titre_evenement', 'date', 'lieu', 
            'image', 'type_evenement', 'latitude', 'longitude', 'heure_debut', 'heure_fin',
            'tickets', 'sessions', 'nombre_tickets_total', 'stock_total', 'is_favorite'
        ]
    
    def get_tickets(self, obj):
        """Retourner tous les tickets associés à cet événement"""
        from .ticket_serializers import TicketListSerializer
        tickets = obj.ticket_set.all()
        return TicketListSerializer(tickets, many=True).data
    
    def get_sessions(self, obj):
        """Retourner toutes les sessions associées à cet événement"""
        from .session_serializers import SessionSerializer
        sessions = obj.sessions.all()
        return SessionSerializer(sessions, many=True).data
    
    def get_nombre_tickets_total(self, obj):
        """Retourner le nombre de types de tickets différents"""
        return obj.ticket_set.count()
    
    def get_stock_total(self, obj):
        """Retourner le stock total de tous les tickets"""
        return sum(ticket.stock for ticket in obj.ticket_set.all())
    
    def get_is_favorite(self, obj):
        """Vérifier si l'utilisateur actuel a favorisé cet événement"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            from ..models.favori import Favori
            from ..models.utilisateurs import Utilisateur
            # Vérifier que c'est un utilisateur et non un administrateur
            if isinstance(request.user, Utilisateur):
                return Favori.objects.filter(utilisateur=request.user, evenement=obj).exists()
        return False 

