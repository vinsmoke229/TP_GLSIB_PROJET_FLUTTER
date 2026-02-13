from django.urls import path, include
from rest_framework.routers import DefaultRouter
from ..views.gestion_achat import AchatViewSet

router = DefaultRouter()
router.register(r'achats', AchatViewSet, basename='achat')

urlpatterns = [
    path('', include(router.urls)),
]

# Routes générées automatiquement par le router:
# GET    /api/achats/                               - Liste tous les achats
# POST   /api/achats/                               - Créer un achat
# GET    /api/achats/{id}/                          - Détails d'un achat
# DELETE /api/achats/{id}/                          - Annuler un achat (< 24h)
# GET    /api/achats/par_utilisateur/?id_utilisateur=1 - Achats d'un utilisateur
# GET    /api/achats/par_evenement/?id_evenement=1  - Achats pour un événement
# GET    /api/achats/recents/                       - Achats récents (< 24h)
# GET    /api/achats/statistiques/                  - Statistiques d'achats
