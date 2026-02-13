from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction as db_transaction

from ..models.transaction import Transaction
from ..models.utilisateurs import Utilisateur
from ..serializers.transaction_serializers import (
    TransactionSerializer, 
    DepotSerializer, 
    TransactionListSerializer,
    TransactionDetailSerializer
)


class TransactionViewSet(viewsets.ModelViewSet):
    queryset = Transaction.objects.all()
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'list':
            return TransactionListSerializer
        elif self.action == 'retrieve':
            return TransactionDetailSerializer
        return TransactionSerializer
    
    def get_queryset(self):
        """Filtrer les transactions par utilisateur connecté"""
        user_id = self.request.user.id_utilisateur
        return Transaction.objects.filter(id_utilisateur=user_id).select_related('id_utilisateur', 'id_achat')
    
    @action(detail=False, methods=['post'])
    def depot(self, request):
        serializer = DepotSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        montant = serializer.validated_data['montant']
        moyen_paiement = serializer.validated_data['moyen_paiement']        
        try:
            utilisateur = Utilisateur.objects.get(id_utilisateur=request.user.id_utilisateur)
            
            with db_transaction.atomic():
                # Créer la transaction
                transaction_obj = Transaction.objects.create(
                    id_utilisateur=utilisateur,
                    montant=montant,
                    type_transaction='depot',
                    moyen_paiement=moyen_paiement
                )
                
                # Mettre à jour le solde
                utilisateur.solde += montant
                utilisateur.save(update_fields=['solde'])
            
            return Response({
                'message': 'Dépôt effectué avec succès',
                'transaction': TransactionSerializer(transaction_obj).data,
                'nouveau_solde': float(utilisateur.solde)
            }, status=status.HTTP_201_CREATED)
        
        except Utilisateur.DoesNotExist:
            return Response(
                {'error': 'Utilisateur non trouvé'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Erreur lors du dépôt: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def historique(self, request):
        utilisateur_id = request.user.id_utilisateur
        transactions = Transaction.objects.filter(id_utilisateur=utilisateur_id).order_by('-date_transaction')
    
        type_filter = request.query_params.get('type', None)
        if type_filter:
            transactions = transactions.filter(type_transaction=type_filter)
        serializer = TransactionListSerializer(transactions, many=True)
        
        # Calculer les totaux
        total_depots = sum(
            t.montant for t in transactions 
            if t.type_transaction in ['depot', 'bonus_parrainage']
        )
        total_debits = sum(
            t.montant for t in transactions 
            if t.type_transaction in ['achat', 'retrait']
        )
        return Response({
            'count': transactions.count(),
            'total_depots': float(total_depots),
            'total_debits': float(total_debits),
            'transactions': serializer.data
        }, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def solde(self, request):
        try:
            utilisateur = Utilisateur.objects.get(id_utilisateur=request.user.id_utilisateur)
            return Response({
                'solde': float(utilisateur.solde),
                'utilisateur': {
                    'id': utilisateur.id_utilisateur,
                    'nom_complet': f"{utilisateur.prenom} {utilisateur.nom}",
                    'email': utilisateur.email
                }
            }, status=status.HTTP_200_OK)
        except Utilisateur.DoesNotExist:
            return Response(
                {'error': 'Utilisateur non trouvé'},
                status=status.HTTP_404_NOT_FOUND
            )
