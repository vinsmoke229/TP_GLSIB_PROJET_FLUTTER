from django.urls import path, include
from rest_framework.routers import DefaultRouter
from ..views.gestion_utilisa import UtilisateurViewSet

router = DefaultRouter()
router.register(r'utilisateurs', UtilisateurViewSet, basename='utilisateur')

urlpatterns = [
    path('', include(router.urls)),
]

# Routes générées automatiquement par le router:
# POST   /api/utilisateurs/                          - ✅ INSCRIPTION PUBLIQUE (génère JWT token)
#                                                      Champs requis: nom, prenom, email, tel, mot_de_passe, mot_de_passe_confirmation
#                                                      Champs optionnels: nom_utilisateur, adresse, code_parrainage_utilise
# GET    /api/utilisateurs/                          - Liste tous les utilisateurs
# GET    /api/utilisateurs/{id}/                     - Détails d'un utilisateur
# PUT    /api/utilisateurs/{id}/                     - Mise à jour complète
# PATCH  /api/utilisateurs/{id}/                     - Mise à jour partielle
# DELETE /api/utilisateurs/{id}/                     - Supprimer un utilisateur
# POST   /api/utilisateurs/{id}/desactiver/          - Désactiver un utilisateur
# POST   /api/utilisateurs/{id}/activer/             - Activer un utilisateur
# POST   /api/utilisateurs/{id}/changer_mot_de_passe/ - Changer le mot de passe
# POST   /api/utilisateurs/{id}/recharger/           - Recharger le compte utilisateur
# GET    /api/utilisateurs/rechercher/?q=text        - Rechercher des utilisateurs
