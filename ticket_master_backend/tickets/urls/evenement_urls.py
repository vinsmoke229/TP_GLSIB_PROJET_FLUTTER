"""
URLs pour la gestion des événements
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from ..views.gestion_evenement import EvenementViewSet

router = DefaultRouter()
router.register(r'evenements', EvenementViewSet, basename='evenement')

urlpatterns = [
    path('', include(router.urls)),
]

# GET    /api/evenements/                       - Liste tous les événements
# POST   /api/evenements/                       - Créer un événement
# GET    /api/evenements/{id}/                  - Détails d'un événement
# PUT    /api/evenements/{id}/                  - Mise à jour complète
# PATCH  /api/evenements/{id}/                  - Mise à jour partielle
# DELETE /api/evenements/{id}/                  - Supprimer un événement
# GET    /api/evenements/a_venir/               - Liste les événements à venir
# GET    /api/evenements/passes/                - Liste les événements passés
# GET    /api/evenements/{id}/tickets/          - Liste les tickets d'un événement
# GET    /api/evenements/par_type/?type=concert - Filtre par type d'événement
# GET    /api/evenements/rechercher/?q=text     - Rechercher des événements
