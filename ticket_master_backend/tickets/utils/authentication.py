import jwt
from datetime import datetime, timedelta
from django.conf import settings
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed
from ..models.administrateurs import Administrateur
from ..models.utilisateurs import Utilisateur


def get_jwt_secret():
    return getattr(settings, 'JWT_SECRET_KEY')


def generate_jwt_token(user_id, email, role, expiration_hours=24):
    expiration = datetime.utcnow() + timedelta(hours=expiration_hours)
    
    payload = {
        'user_id': user_id,
        'email': email,
        'role': role,
        'exp': expiration,
        'iat': datetime.utcnow()
    }
    
    token = jwt.encode(payload, get_jwt_secret(), algorithm='HS256')
    
    return token, expiration


def decode_jwt_token(token):
    try:
        payload = jwt.decode(token, get_jwt_secret(), algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        raise AuthenticationFailed('Le token a expiré.')
    except jwt.InvalidTokenError:
        raise AuthenticationFailed('Token invalide.')


class JWTAuthentication(BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        
        if not auth_header.startswith('Bearer '):
            return None
        
        token = auth_header.split(' ')[1]
        
        try:
            payload = decode_jwt_token(token)
        except AuthenticationFailed:
            return None
        
        # Récupérer l'utilisateur selon le rôle
        role = payload.get('role')
        user_id = payload.get('user_id')
        
        if role == 'admin':
            try:
                user = Administrateur.objects.get(id_admin=user_id)
                return (user, token)
            except Administrateur.DoesNotExist:
                # Retourner None au lieu de lever une exception permet de continuer
                # comme utilisateur anonyme (utile pour les endpoints publics comme login)
                return None
        
        elif role == 'user':
            try:
                user = Utilisateur.objects.get(id_utilisateur=user_id)
                
                # Vérifier que l'utilisateur est actif
                if user.statut != 'actif':
                    raise AuthenticationFailed('Compte utilisateur inactif.')
                
                return (user, token)
            except Utilisateur.DoesNotExist:
                # Retourner None au lieu de lever une exception permet de continuer
                # comme utilisateur anonyme (utile pour les endpoints publics comme login)
                return None
        
        else:
            raise AuthenticationFailed('Rôle invalide dans le token.')
    
    def authenticate_header(self, request):
        return 'Bearer'
