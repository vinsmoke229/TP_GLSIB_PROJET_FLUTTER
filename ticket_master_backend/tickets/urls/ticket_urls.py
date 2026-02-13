from django.urls import path, include
from rest_framework.routers import DefaultRouter
from ..views.gestion_ticket import TicketViewSet

router = DefaultRouter()
router.register(r'tickets', TicketViewSet, basename='ticket')

urlpatterns = [
    path('', include(router.urls)),
]

# Routes générées automatiquement par le router:
# GET    /api/tickets/                       - Liste tous les tickets
# POST   /api/tickets/                       - Créer un ticket
# GET    /api/tickets/{id}/                  - Détails d'un ticket
# PUT    /api/tickets/{id}/                  - Mise à jour complète
# PATCH  /api/tickets/{id}/                  - Mise à jour partielle
# DELETE /api/tickets/{id}/                  - Supprimer un ticket
# GET    /api/tickets/disponibles/           - Liste les tickets disponibles
# POST   /api/tickets/{id}/modifier_stock/   - Modifier le stock d'un ticket
