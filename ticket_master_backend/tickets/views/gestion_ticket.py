from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from ..models.evenements import Evenement
from ..models.ticket import Ticket
from ..permission import IsAdministrateur
from ..serializers.ticket_serializers import (
    TicketSerializer,
    TicketCreateSerializer,
    TicketUpdateSerializer,
    TicketListSerializer
)

class TicketViewSet(viewsets.ModelViewSet):
    queryset = Ticket.objects.all()
    serializer_class = TicketSerializer
    permission_classes = [AllowAny]
    lookup_field = 'id_ticket'
    
    def get_serializer_class(self):
        if self.action == 'create':
            return TicketCreateSerializer
        elif self.action in ['update']:
            return TicketUpdateSerializer
        elif self.action == 'list':
            return TicketListSerializer
        return TicketSerializer

    def get_permissions(self):
        if self.action in ['create', 'update',  'destroy','updatestock']:
            permission_classes = [IsAdministrateur]
        else:
            permission_classes = [AllowAny]
        
        return [permission() for permission in permission_classes]
    
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Vérifier que l'événement existe
        id_evenement = request.data.get('id_evenement')
        if not id_evenement:
            return Response(
                {'error': 'id_evenement est requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            evenement = Evenement.objects.get(id_evenement=id_evenement)
        except Evenement.DoesNotExist:
            return Response(
                {'error': 'Événement non trouvé.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        ticket = serializer.save()
        return Response(
            {
                'message': 'Ticket créé avec succès.',
                'ticket': TicketSerializer(ticket).data
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
                'message': 'Ticket mis à jour avec succès.',
                'ticket': TicketSerializer(instance).data
            }
        )
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        id_ticket = instance.id_ticket
        self.perform_destroy(instance)
        return Response(
            {'message': f'Ticket {id_ticket} supprimé avec succès.'},
            status=status.HTTP_200_OK
        )
    @action(detail=True, methods=['post', 'patch'])
    def update_stock(self, request, id_ticket=None):
        ticket = self.get_object()
        new_stock = request.data.get('stock')
        
        if new_stock is None:
            return Response(
                {'error': 'Le stock est requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            ticket.stock = int(new_stock)
            if ticket.stock < 0:
                return Response(
                    {'error': 'Le stock ne peut pas être négatif.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            ticket.save()
            return Response(
                {
                    'message': 'Stock mis à jour avec succès.',
                    'id_ticket': ticket.id_ticket,
                    'stock': ticket.stock
                },
                status=status.HTTP_200_OK
            )
        except ValueError:
            return Response(
                {'error': 'Le stock doit être un entier.'},
                status=status.HTTP_400_BAD_REQUEST
            )

