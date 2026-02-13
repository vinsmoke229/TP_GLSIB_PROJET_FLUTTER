from django.urls import path, include
from rest_framework.routers import DefaultRouter
from ..views.gestion_favori import FavoriViewSet

router = DefaultRouter()
router.register(r'favorites', FavoriViewSet, basename='favori')

urlpatterns = [
    path('', include(router.urls)),
]

# Routes générées automatiquement par le router:
# GET    /api/favorites/                      - Liste les favoris de l'utilisateur
# POST   /api/favorites/toggle/                - Ajouter/retirer un événement des favoris
# GET    /api/favorites/list_by_user/         - Liste les favoris de l'utilisateur
