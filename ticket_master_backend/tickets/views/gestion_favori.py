from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

from ..models.favori import Favori
from ..models.evenements import Evenement
from ..serializers.favori_serializers import FavoriSerializer, FavoriListSerializer, FavoriDetailSerializer


class FavoriViewSet(viewsets.ModelViewSet):
    """Viewset pour gérer les favoris (ajout, suppression, liste)"""
    queryset = Favori.objects.all()
    serializer_class = FavoriSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'id_favori'
    
    def get_serializer_class(self):
        if self.action == 'list':
            return FavoriListSerializer
        elif self.action == 'retrieve':
            return FavoriDetailSerializer
        return FavoriSerializer
    
    def get_queryset(self):
        """Retourner seulement les favoris de l'utilisateur authentifié"""
        return Favori.objects.filter(utilisateur=self.request.user)
    
    @action(detail=False, methods=['post'])
    def toggle(self, request):
        """
        Endpoint: POST /api/favorites/toggle/
        Ajoute ou supprime un événement des favoris de l'utilisateur
        Body: {"id_evenement": 1}
        Response: {"status": "added"|"removed", "id_favori": int|null}
        """
        id_evenement = request.data.get('id_evenement')
        
        if not id_evenement:
            return Response(
                {"error": "id_evenement est requis."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier que l'événement existe
        try:
            evenement = Evenement.objects.get(id_evenement=id_evenement)
        except Evenement.DoesNotExist:
            return Response(
                {"error": f"Événement avec l'ID {id_evenement} n'existe pas."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Chercher si le favori existe déjà
        favori = Favori.objects.filter(
            utilisateur=request.user,
            evenement=evenement
        ).first()
        
        if favori:
            # Le favori existe -> le supprimer
            id_favori = favori.id_favori
            favori.delete()
            return Response(
                {
                    "status": "removed",
                    "message": f"Événement '{evenement.titre_evenement}' retiré des favoris.",
                    "id_evenement": id_evenement
                },
                status=status.HTTP_200_OK
            )
        else:
            # Le favori n'existe pas -> le créer
            favori = Favori.objects.create(
                utilisateur=request.user,
                evenement=evenement
            )
            return Response(
                {
                    "status": "added",
                    "message": f"Événement '{evenement.titre_evenement}' ajouté aux favoris.",
                    "id_favori": favori.id_favori,
                    "id_evenement": id_evenement
                },
                status=status.HTTP_201_CREATED
            )
    
    @action(detail=False, methods=['get'])
    def list_by_user(self, request):
        """
        Endpoint: GET /api/favorites/list_by_user/
        Retourne tous les favoris de l'utilisateur authentifié
        """
        favoris = self.get_queryset()
        serializer = FavoriListSerializer(favoris, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
