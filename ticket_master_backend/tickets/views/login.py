from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.hashers import check_password
from datetime import datetime

from ..models.administrateurs import Administrateur
from ..models.utilisateurs import Utilisateur
from ..serializers.adminSerializers import AdministrateurSerializer
from ..serializers.utilisateur_serializers import UtilisateurDetailSerializer
from ..serializers.loginSerializers import (
    LoginAdministrateurSerializer,
    LoginUtilisateurSerializer,
    VerifyTokenSerializer
)
# Note: UtilisateurCreateSerializer est maintenant utilisé dans gestion_utilisa.py pour POST /api/utilisateurs/
from ..utils.authentication import generate_jwt_token, decode_jwt_token
from ..permission import IsAdministrateur


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def login_administrateur(request):
    serializer = LoginAdministrateurSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    email = serializer.validated_data['email']
    mot_de_passe = serializer.validated_data['mot_de_passe']
    
    try:
        administrateur = Administrateur.objects.get(email=email)
        
        # Vérifier si le mot de passe est un hash ou en clair (pour les tests)
        password_valid = False
        if administrateur.mot_de_passe.startswith('pbkdf2_sha256$') or administrateur.mot_de_passe.startswith('bcrypt$'):
            # C'est un hash, utiliser check_password
            password_valid = check_password(mot_de_passe, administrateur.mot_de_passe)
        else:
            # C'est en clair (DEV ONLY), comparer directement
            password_valid = (mot_de_passe == administrateur.mot_de_passe)
        
        if password_valid:
            token, expiration = generate_jwt_token(
                user_id=administrateur.id_admin,
                email=administrateur.email,
                role='admin',
                expiration_hours=24 
            )
            return Response(
                {
                    "token": token,
                    "expiration": expiration.isoformat(),
                    "administrateur": AdministrateurSerializer(administrateur).data
                },
                status=status.HTTP_200_OK
            )
        else:
            return Response(
                {"error": "Email ou mot de passe incorrect"},
                status=status.HTTP_401_UNAUTHORIZED
            )
    except Administrateur.DoesNotExist:
        return Response(
            {"error": "Email ou mot de passe incorrect"},
            status=status.HTTP_401_UNAUTHORIZED
        )


from rest_framework.decorators import api_view, permission_classes, authentication_classes

@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def login_utilisateur(request):
    serializer = LoginUtilisateurSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    identifiant = serializer.validated_data['identifiant']
    mot_de_passe = serializer.validated_data['mot_de_passe']
    remember_me = serializer.validated_data.get('remember_me', False)
    
    is_email = '@' in identifiant

    try:
        if is_email:
            utilisateur = Utilisateur.objects.get(email=identifiant)
        else:
           
            utilisateur = Utilisateur.objects.get(nom_utilisateur=identifiant)
        
        if utilisateur.statut != 'actif':
            return Response(
                {"error": "Votre compte est inactif. Contactez l'administrateur."},
                status=status.HTTP_403_FORBIDDEN
            )
        password_valid = False
        if utilisateur.mot_de_passe.startswith('pbkdf2_sha256$') or utilisateur.mot_de_passe.startswith('bcrypt$'):
            password_valid = check_password(mot_de_passe, utilisateur.mot_de_passe)
        else:
            password_valid = (mot_de_passe == utilisateur.mot_de_passe)
        
        if password_valid:
            utilisateur.last_login = datetime.now()
            utilisateur.save(update_fields=['last_login'])
            expiration_hours = 24 * 7 if remember_me else 24
            
            token, expiration = generate_jwt_token(
                user_id=utilisateur.id_utilisateur,
                email=utilisateur.email,
                role='user',
                expiration_hours=expiration_hours
            )
            return Response(
                {
                    "message": "Authentification réussie",
                    "token": token,
                    "expiration": expiration.isoformat(),
                    "remember_me": remember_me,
                    "utilisateur": UtilisateurDetailSerializer(utilisateur).data
                },
                status=status.HTTP_200_OK
            )
        else:
            return Response(
                {"error": "Identifiant ou mot de passe incorrect"},
                status=status.HTTP_401_UNAUTHORIZED
            )
    except Utilisateur.DoesNotExist:
        return Response(
            {"error": "Identifiant ou mot de passe incorrect"},
            status=status.HTTP_401_UNAUTHORIZED
        )

@api_view(['POST'])
def verify_token(request):
    serializer = VerifyTokenSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    token = serializer.validated_data['token']
    
    try:
        payload = decode_jwt_token(token)
        
        return Response(
            {
                "valid": True,
                "user": {
                    "user_id": payload.get('user_id'),
                    "email": payload.get('email'),
                    "role": payload.get('role'),
                    "expiration": datetime.utcfromtimestamp(payload.get('exp')).isoformat()
                }
            },
            status=status.HTTP_200_OK
        )
    except Exception as e:
        return Response(
            {
                "valid": False,
                "error": str(e)
            },
            status=status.HTTP_401_UNAUTHORIZED
        )

def get_token_expiration(remember_me=False):
    if remember_me:
        return 24 * 7
    return 24  
