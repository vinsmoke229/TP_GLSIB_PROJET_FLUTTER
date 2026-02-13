from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth.hashers import check_password
from django.contrib.auth.hashers import make_password
from decimal import Decimal

from ..models.utilisateurs import Utilisateur
from ..serializers import (
    UtilisateurSerializer,
    UtilisateurUpdateSerializer,
    UtilisateurListSerializer,
    UtilisateurDetailSerializer,
    UtilisateurChangePasswordSerializer,
    UtilisateurCreateSerializer,
    UtilisateurRegisterResponseSerializer
)
from ..utils.authentication import generate_jwt_token


class UtilisateurViewSet(viewsets.ModelViewSet):
    queryset = Utilisateur.objects.all()
    serializer_class = UtilisateurSerializer
    permission_classes = [AllowAny]
    lookup_field = 'id_utilisateur'
    
    def get_permissions(self):
        """Définir les permissions par action"""
        if self.action in ['create', 'list']:
            # Création et liste publiques
            permission_classes = [AllowAny]
        elif self.action in ['update', 'partial_update', 'retrieve', 'destroy', 
                            'desactiver', 'activer', 'changer_mot_de_passe', 'recharger']:
            # Actions sécurisées nécessitant une authentification
            permission_classes = [IsAuthenticated]
        elif self.action == 'rechercher':
            permission_classes = [AllowAny]
        else:
            permission_classes = [IsAuthenticated]
        
        return [permission() for permission in permission_classes]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return UtilisateurCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return UtilisateurUpdateSerializer
        elif self.action == 'list':
            return UtilisateurListSerializer
        elif self.action == 'retrieve':
            return UtilisateurDetailSerializer
        elif self.action == 'changer_mot_de_passe':
            return UtilisateurChangePasswordSerializer
        return UtilisateurSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        
        if not serializer.is_valid():
            # Afficher les erreurs dans les logs pour le débogage
            print("Erreurs de validation lors de la création d'utilisateur:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Créer le nouvel utilisateur (avec système de parrainage intégré)
        utilisateur = serializer.save()
        
        # Générer un JWT token automatiquement
        token, expiration = generate_jwt_token(
            user_id=utilisateur.id_utilisateur,
            email=utilisateur.email,
            role='user',
            expiration_hours=24
        )
        
        return Response(
            {
                'message': 'Inscription réussie. Vous êtes maintenant connecté.',
                'token': token,
                'expiration': expiration.isoformat(),
                'utilisateur': UtilisateurRegisterResponseSerializer(utilisateur).data
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
                'message': 'Utilisateur mis à jour avec succès.',
                'utilisateur': UtilisateurDetailSerializer(instance).data
            }
        )
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        id_utilisateur = instance.id_utilisateur
        nom_complet = f"{instance.prenom} {instance.nom}"
        self.perform_destroy(instance)
        return Response(
            {'message': f'Utilisateur {nom_complet} (ID: {id_utilisateur}) supprimé avec succès.'},
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['post', 'patch'])
    def desactiver(self, request, id_utilisateur=None):
        utilisateur = self.get_object()
        
        if utilisateur.statut == 'inactif':
            return Response(
                {'message': 'Cet utilisateur est déjà inactif.'},
                status=status.HTTP_200_OK
            )
        
        utilisateur.statut = 'inactif'
        utilisateur.save()
        
        return Response(
            {
                'message': 'Utilisateur désactivé avec succès.',
                'utilisateur': UtilisateurDetailSerializer(utilisateur).data
            },
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['post', 'patch'])
    def activer(self, request, id_utilisateur=None):
        utilisateur = self.get_object()
        
        if utilisateur.statut == 'actif':
            return Response(
                {'message': 'Cet utilisateur est déjà actif.'},
                status=status.HTTP_200_OK
            )
        
        utilisateur.statut = 'actif'
        utilisateur.save()
        
        return Response(
            {
                'message': 'Utilisateur activé avec succès.',
                'utilisateur': UtilisateurDetailSerializer(utilisateur).data
            },
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['post'])
    def changer_mot_de_passe(self, request, id_utilisateur=None):
        utilisateur = self.get_object()
        serializer = self.get_serializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        ancien_mot_de_passe = serializer.validated_data['ancien_mot_de_passe']
        if not check_password(ancien_mot_de_passe, utilisateur.mot_de_passe):
            return Response(
                {'error': 'L\'ancien mot de passe est incorrect.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        utilisateur.mot_de_passe = make_password(serializer.validated_data['nouveau_mot_de_passe'])
        utilisateur.save()
        
        return Response(
            {'message': 'Mot de passe changé avec succès.'},
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=['get'])

    def rechercher(self, request):
        query = request.query_params.get('q', '')
        
        if not query:
            return Response(
                {'error': 'Le paramètre de recherche "q" est requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        utilisateurs = self.queryset.filter(
            nom__icontains=query
        ) | self.queryset.filter(
            prenom__icontains=query
        ) | self.queryset.filter(
            email__icontains=query
        )
        
        serializer = UtilisateurListSerializer(utilisateurs, many=True)
        return Response({
            'count': utilisateurs.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def recharger(self, request, id_utilisateur=None):
        from django.db import transaction
        
        utilisateur = self.get_object()
        montant = request.data.get('montant')
        
        if not montant:
            return Response(
                {'error': 'Le montant est requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            montant = Decimal(str(montant))
            if montant <= 0:
                return Response(
                    {'error': 'Le montant doit être supérieur à 0.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except (ValueError, TypeError):
            return Response(
                {'error': 'Le montant doit être un nombre valide.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # CRITICAL: Wrap in atomic transaction to prevent race conditions (Bug #2 fix)
        with transaction.atomic():
            ancien_solde = utilisateur.solde
            utilisateur.solde += montant
            utilisateur.save()
        
        return Response(
            {
                'message': f'Recharge de {montant} effectuée avec succès.',
                'ancien_solde': float(ancien_solde),
                'nouveau_solde': float(utilisateur.solde),
                'montant_ajoute': float(montant)
            },
            status=status.HTTP_200_OK
        )
