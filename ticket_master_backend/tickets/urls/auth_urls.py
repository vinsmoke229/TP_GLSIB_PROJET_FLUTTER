from django.urls import path
from ..views.login import (
    login_administrateur,
    login_utilisateur,
    verify_token,
)

urlpatterns = [
    path('login/admin/', login_administrateur, name='login-administrateur'),
    path('login/utilisateur/', login_utilisateur, name='login-utilisateur'),
    path('verify-token/', verify_token, name='verify-token'),
]

# Routes disponibles:
# POST   /api/auth/login/admin/             - Connexion administrateur
# POST   /api/auth/login/utilisateur/       - Connexion utilisateur
# POST   /api/auth/verify-token/            - Vérifier la validité d'un token JWT

# ✅ L'inscription d'utilisateur se fait maintenant via: POST /api/utilisateurs/ (voir utilisateur_urls.py)

