from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from ..models.utilisateurs import Utilisateur
from ..models.administrateurs import Administrateur


class LoginAdministrateurSerializer(serializers.Serializer):
    """Serializer pour la connexion administrateur"""
    email = serializers.EmailField(required=True, help_text="Email de l'administrateur")
    mot_de_passe = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        help_text="Mot de passe"
    )


class LoginUtilisateurSerializer(serializers.Serializer):
    """Serializer pour la connexion utilisateur"""
    identifiant = serializers.CharField(
        required=True,
        help_text="Email ou nom d'utilisateur"
    )
    mot_de_passe = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        help_text="Mot de passe"
    )
    remember_me = serializers.BooleanField(
        required=False,
        default=False,
        help_text="Se souvenir de moi (7 jours au lieu de 24h)"
    )

class UtilisateurRegisterResponseSerializer(serializers.ModelSerializer):
    """Serializer pour la réponse après inscription (pas de données sensibles)"""
    nom_complet = serializers.SerializerMethodField()
    
    class Meta:
        model = Utilisateur
        fields = [
            'id_utilisateur',
            'nom',
            'prenom',
            'nom_complet',
            'email',
            'tel',
            'statut',
            'solde',
            'code_parrainage',
            'nom_utilisateur',
            'adresse',
            'photo_profil'
        ]
        read_only_fields = ['id_utilisateur', 'statut', 'solde', 'code_parrainage']
    
    def get_nom_complet(self, obj):
        """Retourner le nom complet de l'utilisateur"""
        return f"{obj.prenom} {obj.nom}"


class VerifyTokenSerializer(serializers.Serializer):
    """Serializer pour vérifier la validité d'un token JWT"""
    token = serializers.CharField(required=True, help_text="Token JWT à vérifier")


class LoginResponseSerializer(serializers.Serializer):
    """Serializer pour la réponse de connexion (documentation)"""
    token = serializers.CharField(help_text="Token JWT pour les requêtes suivantes")
    expiration = serializers.DateTimeField(help_text="Date et heure d'expiration du token")
    message = serializers.CharField(required=False, help_text="Message de succès")
