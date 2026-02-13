from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from ..models.administrateurs import Administrateur


class AdministrateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Administrateur
        fields = ['id_admin', 'nom', 'prenom', 'email', 'role', 'status', 'photo_profil']
        read_only_fields = ['id_admin']

class AdministrateurCreateSerializer(serializers.ModelSerializer):
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
    
    class Meta:
        model = Administrateur
        fields = ['nom', 'prenom', 'email', 'mot_de_passe', 'mot_de_passe_confirmation', 'role', 'status']
        extra_kwargs = {
            'email': {'required': True}
        }
    
    def validate_email(self, value):
        if Administrateur.objects.filter(email=value).exists():
            raise serializers.ValidationError("Un administrateur avec cet email existe déjà.")
        return value.lower()
    
    def validate(self, data):
        if data['mot_de_passe'] != data.get('mot_de_passe_confirmation'):
            raise serializers.ValidationError({
                "mot_de_passe_confirmation": "Les mots de passe ne correspondent pas."
            })
        return data
    
    def create(self, validated_data):
        validated_data.pop('mot_de_passe_confirmation', None)
        validated_data['mot_de_passe'] = make_password(validated_data['mot_de_passe'])
        return super().create(validated_data)


class AdministrateurUpdateSerializer(serializers.ModelSerializer):
    mot_de_passe = serializers.CharField(
        write_only=True,
        required=False,
        style={'input_type': 'password'},
        help_text="Nouveau mot de passe (optionnel)"
    )
    mot_de_passe_confirmation = serializers.CharField(
        write_only=True,
        required=False,
        style={'input_type': 'password'},
        help_text="Confirmez le nouveau mot de passe"
    )
    
    class Meta:
        model = Administrateur
        fields = ['nom', 'prenom', 'email', 'mot_de_passe', 'mot_de_passe_confirmation', 'role', 'status', 'photo_profil']
        extra_kwargs = {
            'nom': {'required': True},
            'prenom': {'required': True},
            'email': {'required': True},
            'role': {'required': True},
            'photo_profil': {'required': False},
        }
    
    def validate_email(self, value):
        administrateur = self.instance
        if Administrateur.objects.filter(email=value).exclude(id_admin=administrateur.id_admin).exists():
            raise serializers.ValidationError("Un administrateur avec cet email existe déjà.")
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


class AdministrateurPartialUpdateSerializer(serializers.ModelSerializer):
    mot_de_passe = serializers.CharField(
        write_only=True,
        required=False,
        style={'input_type': 'password'},
        help_text="Nouveau mot de passe (optionnel)"
    )
    mot_de_passe_confirmation = serializers.CharField(
        write_only=True,
        required=False,
        style={'input_type': 'password'},
        help_text="Confirmez le nouveau mot de passe"
    )
    
    class Meta:
        model = Administrateur
        fields = ['nom', 'prenom', 'email', 'mot_de_passe', 'mot_de_passe_confirmation', 'role', 'status', 'photo_profil']
        extra_kwargs = {
            'nom': {'required': False},
            'prenom': {'required': False},
            'email': {'required': False},
            'role': {'required': False},
            'status': {'required': False},
            'photo_profil': {'required': False},
        }
    
    def validate_email(self, value):
        administrateur = self.instance
        if Administrateur.objects.filter(email=value).exclude(id_admin=administrateur.id_admin).exists():
            raise serializers.ValidationError("Un administrateur avec cet email existe déjà.")
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


class AdministrateurListSerializer(serializers.ModelSerializer):
    nom_complet = serializers.SerializerMethodField()
    
    class Meta:
        model = Administrateur
        fields = ['id_admin', 'nom', 'prenom', 'nom_complet', 'email', 'role', 'status', 'photo_profil']
    
    def get_nom_complet(self, obj):
        return f"{obj.prenom} {obj.nom}"


class AdministrateurChangePasswordSerializer(serializers.Serializer):
    ancien_mot_de_passe = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )
    nouveau_mot_de_passe = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )
    nouveau_mot_de_passe_confirmation = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )
    
    def validate(self, data):
        if data['nouveau_mot_de_passe'] != data['nouveau_mot_de_passe_confirmation']:
            raise serializers.ValidationError({
                "nouveau_mot_de_passe_confirmation": "Les mots de passe ne correspondent pas."
            })
        return data
