from django.urls import path, include
from rest_framework.routers import DefaultRouter
from ..views.gestion_admin import AdministrateurViewSet

router = DefaultRouter()
router.register(r'administrateurs', AdministrateurViewSet, basename='administrateur')

urlpatterns = [
    path('', include(router.urls)),
]

# Routes générées automatiquement par le router:
# GET    /api/administrateurs/                          - Liste tous les administrateurs
# POST   /api/administrateurs/                          - Créer un administrateur
# GET    /api/administrateurs/{id}/                     - Détails d'un administrateur
# PUT    /api/administrateurs/{id}/                     - Mise à jour complète
# PATCH  /api/administrateurs/{id}/                     - Mise à jour partielle
# DELETE /api/administrateurs/{id}/                     - Supprimer un administrateur
# POST   /api/administrateurs/{id}/changer_mot_de_passe/ - Changer le mot de passe
# GET    /api/administrateurs/rechercher/?q=text        - Rechercher des administrateurs
