from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.db.models import Q
from datetime import date
from ..serializers.ticket_serializers import TicketListSerializer
from ..models.evenements import Evenement
from ..serializers import EvenementSerializer
from ..serializers.evenement_serializers import (
    EvenementCreateSerializer,
    EvenementUpdateSerializer,
    EvenementListSerializer,
    EvenementDetailSerializer
)
from ..permission import IsAdministrateur


class EvenementViewSet(viewsets.ModelViewSet):
    queryset = Evenement.objects.all().order_by('-date')
    serializer_class = EvenementSerializer
    lookup_field = 'id_evenement'
    
    def get_permissions(self):
        if self.action in ['create', 'update',  'destroy']:
            permission_classes = [IsAdministrateur]
        else:
            permission_classes = [AllowAny]
        
        return [permission() for permission in permission_classes]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return EvenementCreateSerializer
        elif self.action in ['update']:
            return EvenementUpdateSerializer
        elif self.action == 'list':
            return EvenementListSerializer
        elif self.action == 'retrieve':
            return EvenementDetailSerializer
        return EvenementSerializer
    
    def list(self, request, *args, **kwargs):
        """Lister les événements avec filtrage optionnel par type_evenement"""
        queryset = self.filter_queryset(self.get_queryset())
        
        # Filtrage par type_evenement
        type_filter = request.query_params.get('type', None)
        if type_filter:
            queryset = queryset.filter(type_evenement__icontains=type_filter)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response(serializer.data)
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        
        if not serializer.is_valid():
            print("Erreurs de validation:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        evenement = serializer.save()
        return Response(
            {
                'message': 'Événement créé avec succès.',
                'evenement': EvenementDetailSerializer(evenement).data
            },
            status=status.HTTP_201_CREATED
        )
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', True)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        self.perform_update(serializer)
        
        return Response(
            {
                'message': 'Événement mis à jour avec succès.',
                'evenement': EvenementDetailSerializer(instance).data
            }
        )
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        
        nombre_tickets = instance.ticket_set.count()
        if nombre_tickets > 0:
            return Response(
                {
                    'error': f'Impossible de supprimer cet événement. '
                             f'Il a {nombre_tickets} ticket(s) associé(s). '
                             f'Supprimez d\'abord les tickets.'
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        titre = instance.titre_evenement
        self.perform_destroy(instance)
        return Response(
            {'message': f'Événement "{titre}" supprimé avec succès.'},
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=['get'])
    def a_venir(self, request):
        evenements = self.queryset.filter(date__gte=date.today()).order_by('date')
        serializer = EvenementListSerializer(evenements, many=True)
        return Response({
            'count': evenements.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def passes(self, request):
        evenements = self.queryset.filter(date__lt=date.today()).order_by('-date')
        serializer = EvenementListSerializer(evenements, many=True)
        return Response({
            'count': evenements.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['get'])
    def tickets(self, request, id_evenement=None):
        evenement = self.get_object()
        tickets = evenement.ticket_set.all()
        
        
        serializer = TicketListSerializer(tickets, many=True)
        
        return Response({
            'evenement': evenement.titre_evenement,
            'count': tickets.count(),
            'tickets': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def rechercher(self, request):
        """
        Endpoint: GET /api/evenements/rechercher/?q=query
        Recherche les événements par titre, lieu ou catégorie
        Si q est vide, retourne tous les événements
        """
        query = request.query_params.get('q', '').strip()
        
        if not query:
            # Si pas de query, retourner tous les événements
            evenements = self.get_queryset()
        else:
            # Rechercher dans titre, lieu et type_evenement
            evenements = self.get_queryset().filter(
                Q(titre_evenement__icontains=query) |
                Q(lieu__icontains=query) |
                Q(type_evenement__icontains=query)
            )
        
        # Pagination
        page = self.paginate_queryset(evenements)
        if page is not None:
            serializer = EvenementListSerializer(page, many=True, context={'request': request})
            # Récupérer la réponse paginée standard et l'enrichir
            paginated_response = self.get_paginated_response(serializer.data)
            paginated_response.data['query'] = query
            return paginated_response
        
        serializer = EvenementListSerializer(evenements, many=True, context={'request': request})
        return Response({
            'query': query,
            'count': evenements.count(),
            'results': serializer.data
        })