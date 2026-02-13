from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from ..models.utilisateurs import Utilisateur
import random
import string
class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = ['id_utilisateur', 'nom', 'prenom', 'email', 'statut', 'solde', 'tel', 'photo_profil', 'last_login', 'nom_utilisateur', 'total_code_use', 'code_parrainage', 'adresse']
        read_only_fields = ['id_utilisateur']


class UtilisateurCreateSerializer(serializers.ModelSerializer):
    mot_de_passe = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
    )
    mot_de_passe_confirmation = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        help_text="Confirmez le mot de passe"
    )
    code_parrainage_utilise = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        max_length=6,
        help_text="Code de parrainage d'un autre utilisateur (optionnel)"
    )
    
    class Meta:
        model = Utilisateur
        fields = [
            'nom',
            'prenom',
            'email',
            'tel',
            'mot_de_passe',
            'mot_de_passe_confirmation',
            'code_parrainage_utilise',
            'nom_utilisateur',
            'adresse'
        ]
        extra_kwargs = {
            # Champs OBLIGATOIRES pour le mobile (README_INTEGRATION.md)
            'nom': {'required': True, 'allow_blank': False},
            'prenom': {'required': True, 'allow_blank': False},
            'email': {'required': True, 'allow_blank': False},
            'tel': {'required': True, 'allow_blank': False},
            # Champs optionnels
            'nom_utilisateur': {'required': False, 'allow_blank': True},
            'adresse': {'required': False, 'allow_blank': True},
        }
    
    def validate_email(self, value):
        if Utilisateur.objects.filter(email=value).exists():
            raise serializers.ValidationError("Un utilisateur avec cet email existe déjà.")
        return value.lower()
    def validate_tel(self, value):
        """Valider le format du numéro de téléphone"""
        if not value or len(value.strip()) == 0:
            raise serializers.ValidationError("Le numéro de téléphone est obligatoire.")
        return value.strip()
    
    def validate_code_parrainage_utilise(self, value):
        """Valider que le code de parrainage existe"""
        # Si la valeur est None, vide ou ne contient que des espaces
        if not value or not value.strip():
            return None
        
        # Normaliser le code (enlever les espaces et mettre en majuscules)
        code = value.strip().upper()
        
        # Vérifier que le code existe
        if not Utilisateur.objects.filter(code_parrainage=code).exists():
            raise serializers.ValidationError("Ce code de parrainage n'existe pas.")
        
        return code
    
    def validate(self, data):
        """Valider que les mots de passe correspondent"""
        if data['mot_de_passe'] != data.get('mot_de_passe_confirmation'):
            raise serializers.ValidationError({
                "mot_de_passe_confirmation": "Les mots de passe ne correspondent pas."
            })
        return data
    
    def _generer_code_parrainage(self):
        """Génère un code de parrainage unique de 6 caractères"""
        caracteres = string.ascii_uppercase + string.digits
        while True:
            code = ''.join(random.choices(caracteres, k=6))
            if not Utilisateur.objects.filter(code_parrainage=code).exists():
                return code
    
    def create(self, validated_data):
        from django.db import transaction
        
        # Récupérer le code de parrainage utilisé
        code_parrainage_utilise = validated_data.pop('code_parrainage_utilise', None)
        validated_data.pop('mot_de_passe_confirmation', None)
        
        # Hacher le mot de passe
        validated_data['mot_de_passe'] = make_password(validated_data['mot_de_passe'])
        
        # Génération automatique du code de parrainage unique
        validated_data['code_parrainage'] = self._generer_code_parrainage()
        
        # Initialisation des valeurs par défaut
        validated_data.setdefault('statut', 'actif')
        validated_data.setdefault('total_code_use', 0)
        validated_data.setdefault('solde', 0)
        
        with transaction.atomic():
            # Créer le nouvel utilisateur
            nouvel_utilisateur = super().create(validated_data)
            
            # Si un code de parrainage a été utilisé
            if code_parrainage_utilise:
                try:
                    parrain = Utilisateur.objects.select_for_update().get(code_parrainage=code_parrainage_utilise)
                    
                    # Ajouter 100 FCFA au solde du parrain
                    parrain.solde += 100
                    parrain.total_code_use += 1
                    parrain.save(update_fields=['solde', 'total_code_use'])
                    
                    # Créer une transaction pour tracer le bonus
                    from ..models.transaction import Transaction
                    Transaction.objects.create(
                        id_utilisateur=parrain,
                        montant=100,
                        type_transaction='bonus_parrainage',
                        description=f"Bonus de parrainage pour l'inscription de {nouvel_utilisateur.prenom} {nouvel_utilisateur.nom}"
                    )
                    
                except Utilisateur.DoesNotExist:
                    pass  
        
        return nouvel_utilisateur


class UtilisateurUpdateSerializer(serializers.ModelSerializer):
    mot_de_passe = serializers.CharField(
        write_only=True,
        required=False,
        style={'input_type': 'password'},
    )
    mot_de_passe_confirmation = serializers.CharField(
        write_only=True,
        required=False,
        style={'input_type': 'password'},
        help_text="Confirmez le nouveau mot de passe"
    )
    class Meta:
        model = Utilisateur
        fields = ['nom', 'prenom', 'email', 'statut', 'mot_de_passe', 'mot_de_passe_confirmation', 'tel', 'photo_profil', 'last_login', 'nom_utilisateur', 'total_code_use', 'code_parrainage', 'adresse']
        extra_kwargs = {
            'nom': {'required': False},
            'prenom': {'required': False},
            'email': {'required': False},
            'statut': {'required': False},
            'photo_profil': {'required': False},
            'last_login': {'required': False},
            'nom_utilisateur': {'required': False},
            'total_code_use': {'required': False},
            'code_parrainage': {'required': False},
            'adresse': {'required': False},
        }
    def validate_email(self, value):
        utilisateur = self.instance
        if Utilisateur.objects.filter(email=value).exclude(id_utilisateur=utilisateur.id_utilisateur).exists():
            raise serializers.ValidationError("Un utilisateur avec cet email existe déjà.")
        return value.lower()
    def validate(self, data):
        if 'mot_de_passe' in data:
            if 'mot_de_passe_confirmation' not in data:
                raise serializers.ValidationError({
                    "mot_de_passe_confirmation": "La confirmation du mot de passe est requise."
                })
            if data['mot_de_passe'] != data['mot_de_passe_confirmation']:
                raise serializers.ValidationError({
                    "mot_de_passe_confirmation": "Les mots de passe ne correspondent pas."
                })
        
        return data
    
    def update(self, instance, validated_data):
        validated_data.pop('mot_de_passe_confirmation', None)
        if 'mot_de_passe' in validated_data:
            validated_data['mot_de_passe'] = make_password(validated_data['mot_de_passe'])
        
        return super().update(instance, validated_data)


class UtilisateurListSerializer(serializers.ModelSerializer):
    nom_complet = serializers.SerializerMethodField()
    
    class Meta:
        model = Utilisateur
        fields = ['id_utilisateur', 'nom', 'prenom', 'nom_complet', 'email', 'statut', 'solde', 'tel', 'photo_profil', 'last_login', 'nom_utilisateur', 'total_code_use', 'code_parrainage', 'adresse']
    
    def get_nom_complet(self, obj):
        """Retourner le nom complet de l'utilisateur"""
        return f"{obj.prenom} {obj.nom}"


class UtilisateurDetailSerializer(serializers.ModelSerializer):
    """Serializer détaillé pour un utilisateur spécifique"""
    nom_complet = serializers.SerializerMethodField()
    
    class Meta:
        model = Utilisateur
        fields = ['id_utilisateur', 'nom', 'prenom', 'nom_complet', 'email', 'statut', 'solde', 'tel', 'photo_profil', 'last_login', 'nom_utilisateur', 'total_code_use', 'code_parrainage', 'adresse']
        read_only_fields = ['id_utilisateur']
    
    def get_nom_complet(self, obj):
        """Retourner le nom complet de l'utilisateur"""
        return f"{obj.prenom} {obj.nom}"


class UtilisateurChangePasswordSerializer(serializers.Serializer):
    ancien_mot_de_passe = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )
    nouveau_mot_de_passe = serializers.CharField(
        write_only=True,
        required=True,
        min_length=8,
        style={'input_type': 'password'}
    )
    nouveau_mot_de_passe_confirmation = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )
    
    def validate_nouveau_mot_de_passe(self, value):
        if len(value) < 8:
            raise serializers.ValidationError("Le mot de passe doit contenir au moins 8 caractères.")
        if not any(char.isdigit() for char in value):
            raise serializers.ValidationError("Le mot de passe doit contenir au moins un chiffre.")
        if not any(char.isupper() for char in value):
            raise serializers.ValidationError("Le mot de passe doit contenir au moins une majuscule.")
        return value
    
    def validate(self, data):
        if data['nouveau_mot_de_passe'] != data['nouveau_mot_de_passe_confirmation']:
            raise serializers.ValidationError({
                "nouveau_mot_de_passe_confirmation": "Les mots de passe ne correspondent pas."
            })
        return data
