from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.db.models import Sum
from django.shortcuts import render
from django.utils import timezone
from datetime import datetime, timedelta

from ..models.achat import Achat
from ..models.utilisateurs import Utilisateur
from ..models.ticket import Ticket
from ..serializers.achat_serializers import (
    AchatSerializer,
    AchatCreateSerializer,
    AchatListSerializer,
    AchatDetailSerializer,
)
from ..utils.qr_generator import generate_qr_code
class AchatViewSet(viewsets.ModelViewSet):
    queryset = Achat.objects.all().order_by('-id_achat')  # Tri décroissant : plus récent en premier
    serializer_class = AchatSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'id_achat'
    ordering_fields = ['id_achat', 'date_achat', 'montant_total']
    ordering = '-id_achat'  # Ordre par défaut
    
    def get_permissions(self):
        # Endpoints publics pour le scan de QR code (pas d'authentification requise)
        if self.action in ['scan_qr', 'validate_ticket', 'get_by_qr']:
            permission_classes = [AllowAny]
        elif self.action in ['list', 'retrieve']:
            permission_classes = [IsAuthenticated]
        elif self.action in ['create', 'destroy', 'valider']:
            permission_classes = [IsAuthenticated]
        elif self.action in ['par_utilisateur', 'par_evenement', 'recents', 'statistiques']:
            permission_classes = [IsAuthenticated]
        else:
            permission_classes = [IsAuthenticated]
        
        return [permission() for permission in permission_classes]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return AchatCreateSerializer
        elif self.action == 'list':
            return AchatListSerializer
        elif self.action == 'retrieve':
            return AchatDetailSerializer
        return AchatSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Créer l'achat
        achat = serializer.save()
        
        # Générer le QR code automatiquement
        achat = generate_qr_code(achat, request)
        achat.save()
        
        # Retourner la réponse avec les détails de l'achat et le QR code
        achat_data = AchatDetailSerializer(achat, context={'request': request}).data
        
        return Response(
            {
                'message': 'Achat effectué avec succès.',
                'achat': achat_data,
                'qr_code_url': achat_data.get('qr_code_url'),
                'verification_url': f"{request.build_absolute_uri('/')[:-1]}/api/achats/scan/{achat.code_qr}/"
            },
            status=status.HTTP_201_CREATED
        )
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        ticket = instance.id_ticket
        quantite = instance.quantite
        utilisateur = instance.id_utilisateur
        montant_total = instance.montant_total
        
        time_diff = datetime.now().replace(tzinfo=None) - instance.date_achat.replace(tzinfo=None)
        if time_diff > timedelta(hours=24):
            return Response(
                {'error': 'Impossible d\'annuler un achat de plus de 24 heures.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Restaurer le stock
        ticket.stock += quantite
        ticket.save()
        
        # Refund le solde de l'utilisateur
        utilisateur.solde += montant_total
        utilisateur.save()
        
        id_achat = instance.id_achat
        self.perform_destroy(instance)
        
        return Response(
            {
                'message': f'Achat {id_achat} annulé avec succès. {quantite} ticket(s) remis dans le stock et {montant_total} remboursé au solde.',
                'remboursement': str(montant_total),
                'nouveau_solde': str(utilisateur.solde)
            },
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=['post'])
    def valider(self, request):
        """
        Endpoint: POST /api/achats/valider/
        Valide un ticket via son ID d'achat
        Body: {"id_achat": 1}
        """
        id_achat = request.data.get('id_achat')
        
        if not id_achat:
            return Response(
                {'error': 'id_achat est requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            achat = Achat.objects.get(id_achat=id_achat)
        except Achat.DoesNotExist:
            return Response(
                {'error': 'Achat non trouvé.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Vérifier si le ticket est déjà utilisé
        if achat.est_utilise:
            return Response(
                {
                    'error': 'Ce ticket a déjà été utilisé/validé.',
                    'achat': {
                        'id_achat': achat.id_achat,
                        'date_validation': 'Ticket déjà consommé.'
                    }
                },
                status=status.HTTP_409_CONFLICT
            )
        
        # Marquer le ticket comme utilisé
        achat.est_utilise = True
        achat.save()
        
        return Response(
            {
                'message': 'Ticket validé avec succès.',
                'achat': AchatDetailSerializer(achat).data
            },
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=['get'])
    def par_utilisateur(self, request):
        id_utilisateur = request.query_params.get('id_utilisateur')
        
        if not id_utilisateur:
            return Response(
                {'error': 'Le paramètre id_utilisateur est requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            utilisateur = Utilisateur.objects.get(id_utilisateur=id_utilisateur)
        except Utilisateur.DoesNotExist:
            return Response(
                {'error': 'Utilisateur non trouvé.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        achats = self.queryset.filter(id_utilisateur=id_utilisateur).order_by('-date_achat')
        serializer = AchatListSerializer(achats, many=True)
        
        return Response({
            'utilisateur': f"{utilisateur.prenom} {utilisateur.nom}",
            'count': achats.count(),
            'achats': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def par_evenement(self, request):
        """
        Endpoint: GET /api/achats/par_evenement/?id_evenement=1
        """
        id_evenement = request.query_params.get('id_evenement')
        
        if not id_evenement:
            return Response(
                {'error': 'Le paramètre id_evenement est requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        achats = self.queryset.filter(
            id_ticket__id_evenement=id_evenement
        ).order_by('-date_achat')
        
        serializer = AchatListSerializer(achats, many=True)
        
        return Response({
            'count': achats.count(),
            'achats': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def recents(self, request):
        date_limite = datetime.now() - timedelta(hours=24)
        achats = self.queryset.filter(date_achat__gte=date_limite).order_by('-date_achat')
        
        serializer = AchatListSerializer(achats, many=True)
        
        return Response({
            'count': achats.count(),
            'achats': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def statistiques(self, request):
        total_achats = self.queryset.count()
        
        # Calculer le revenu total et les tickets vendus avec agrégation
        aggregation = self.queryset.aggregate(
            total_revenus=Sum('montant_total'),
            total_tickets_vendus=Sum('quantite')
        )
        
        total_revenus = float(aggregation['total_revenus'] or 0)
        total_tickets_vendus = aggregation['total_tickets_vendus'] or 0
        
        # Trouver le ticket le plus vendu (par quantité totale)
        ticket_stats = self.queryset.values(
            'id_ticket__type'
        ).annotate(
            total_quantite=Sum('quantite')
        ).order_by('-total_quantite').first()
        
        ticket_plus_vendu = ticket_stats['id_ticket__type'] if ticket_stats else 'Aucun'
        
        # Trouver l'événement le plus populaire (par quantité totale)
        evenement_stats = self.queryset.values(
            'id_ticket__id_evenement__titre_evenement'
        ).annotate(
            total_quantite=Sum('quantite')
        ).order_by('-total_quantite').first()
        
        evenement_plus_populaire = evenement_stats['id_ticket__id_evenement__titre_evenement'] if evenement_stats else 'Aucun'
        
        data = {
            'total_achats': total_achats,
            'total_tickets_vendus': total_tickets_vendus,
            'total_revenus': f"{total_revenus:.2f}",
            'ticket_plus_vendu': ticket_plus_vendu,
            'evenement_plus_populaire': evenement_plus_populaire
        }
        
        return Response(data)
    
    @action(detail=False, methods=['get'], url_path='scan/(?P<code_qr>[^/.]+)', permission_classes=[AllowAny])
    def scan_qr(self, request, code_qr=None):
        """
        Page web affichée après scan du QR code
        Affiche les détails de l'achat et permet de valider
        GET /api/achats/scan/{code_qr}/
        """
        try:
            achat = Achat.objects.select_related(
                'id_utilisateur', 
                'id_ticket', 
                'id_ticket__id_evenement'
            ).get(code_qr=code_qr)
            
            # Préparer le contexte pour le template
            context = {
                'achat': achat,
                'utilisateur': achat.id_utilisateur,
                'ticket': achat.id_ticket,
                'evenement': achat.id_ticket.id_evenement,
                'code_qr': code_qr,
                'est_deja_utilise': achat.est_utilise,
                'quantite': achat.quantite,
                'total': achat.montant_total,
            }
            
            return render(request, 'tickets/scan_validation.html', context)
            
        except Achat.DoesNotExist:
            return render(request, 'tickets/scan_error.html', {
                'error': 'QR Code invalide ou ticket non trouvé'
            })
    
    @action(detail=False, methods=['post'], url_path='validate/(?P<code_qr>[^/.]+)', permission_classes=[AllowAny])
    def validate_ticket(self, request, code_qr=None):
        """
        API appelée pour marquer le ticket comme utilisé
        POST /api/achats/validate/{code_qr}/
        Appelée depuis la page de scan après confirmation
        """
        try:
            achat = Achat.objects.select_related(
                'id_utilisateur', 
                'id_ticket', 
                'id_ticket__id_evenement'
            ).get(code_qr=code_qr)
            
            if achat.est_utilise:
                return Response({
                    'success': False,
                    'error': 'Ce ticket a déjà été utilisé',
                    'date_utilisation': achat.date_utilisation
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Marquer comme utilisé
            achat.est_utilise = True
            achat.date_utilisation = timezone.now()
            achat.save()
            
            return Response({
                'success': True,
                'message': 'Ticket validé avec succès',
                'achat': {
                    'id_achat': achat.id_achat,
                    'utilisateur': f"{achat.id_utilisateur.prenom} {achat.id_utilisateur.nom}",
                    'email': achat.id_utilisateur.email,
                    'tel': achat.id_utilisateur.tel,
                    'evenement': achat.id_ticket.id_evenement.titre_evenement,
                    'type_ticket': achat.id_ticket.type,
                    'quantite': achat.quantite,
                    'total': str(achat.montant_total),
                    'date_achat': achat.date_achat,
                    'date_utilisation': achat.date_utilisation,
                    'est_utilise': True
                }
            }, status=status.HTTP_200_OK)
            
        except Achat.DoesNotExist:
            return Response({
                'success': False,
                'error': 'QR Code invalide'
            }, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=False, methods=['get'], url_path='details/(?P<code_qr>[^/.]+)', permission_classes=[AllowAny])
    def get_by_qr(self, request, code_qr=None):
        """
        Récupère les détails d'un achat via son QR code (sans le marquer comme utilisé)
        GET /api/achats/details/{code_qr}/
        """
        try:
            achat = Achat.objects.select_related(
                'id_utilisateur', 
                'id_ticket', 
                'id_ticket__id_evenement'
            ).get(code_qr=code_qr)
            
            return Response({
                'achat': {
                    'id_achat': achat.id_achat,
                    'utilisateur': f"{achat.id_utilisateur.prenom} {achat.id_utilisateur.nom}",
                    'email': achat.id_utilisateur.email,
                    'tel': achat.id_utilisateur.tel,
                    'evenement': achat.id_ticket.id_evenement.titre_evenement,
                    'type_ticket': achat.id_ticket.type,
                    'quantite': achat.quantite,
                    'total': str(achat.montant_total),
                    'date_achat': achat.date_achat,
                    'est_utilise': achat.est_utilise,
                    'date_utilisation': achat.date_utilisation,
                    'qr_code_url': request.build_absolute_uri(achat.qr_image.url) if achat.qr_image else None
                }
            }, status=status.HTTP_200_OK)
            
        except Achat.DoesNotExist:
            return Response({
                'error': 'QR Code invalide'
            }, status=status.HTTP_404_NOT_FOUND)