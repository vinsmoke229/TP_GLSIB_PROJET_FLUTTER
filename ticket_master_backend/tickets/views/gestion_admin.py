from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth.hashers import check_password,make_password
from ..models.administrateurs import Administrateur
from ..serializers.adminSerializers import (
    AdministrateurSerializer,
    AdministrateurCreateSerializer,
    AdministrateurUpdateSerializer,
    AdministrateurListSerializer,
    AdministrateurChangePasswordSerializer
)
from ..permission import IsAdministrateur

class AdministrateurViewSet(viewsets.ModelViewSet):
    queryset = Administrateur.objects.all()
    serializer_class = AdministrateurSerializer
    permission_classes = [IsAdministrateur] 
    lookup_field = 'id_admin'
    
    def get_serializer_class(self):
        if self.action == 'create':
            return AdministrateurCreateSerializer
        elif self.action == 'update':
            return AdministrateurUpdateSerializer
        elif self.action == 'list':
            return AdministrateurListSerializer
        elif self.action == 'changer_mot_de_passe':
            return AdministrateurChangePasswordSerializer
        return AdministrateurSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        
        if not serializer.is_valid():
            print("Erreurs de validation:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        administrateur = serializer.save()
        return Response(
            {
                'message': 'Administrateur créé avec succès.',
                'administrateur': AdministrateurListSerializer(administrateur).data
            },
            status=status.HTTP_201_CREATED
        )
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        self.perform_update(serializer)
        
        return Response(
            {
                'message': 'Administrateur mis à jour avec succès.',
                'administrateur': AdministrateurListSerializer(instance).data
            }
        )
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.role == 'superadmin':
            superadmins_count = Administrateur.objects.filter(role='superadmin').count()
            
            if superadmins_count <= 1:
                return Response(
                    {'error': 'Impossible de supprimer le dernier superadmin.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        id_admin = instance.id_admin
        nom_complet = f"{instance.prenom} {instance.nom}"
        self.perform_destroy(instance)
        return Response(
            {'message': f'Administrateur {nom_complet} (ID: {id_admin}) supprimé avec succès.'},
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['post'])
    def changer_mot_de_passe(self, request, id_admin=None):
      
        administrateur = self.get_object()
        serializer = self.get_serializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        ancien_mot_de_passe = serializer.validated_data['ancien_mot_de_passe']
        if not check_password(ancien_mot_de_passe, administrateur.mot_de_passe):
            return Response(
                {'error': 'L\'ancien mot de passe est incorrect.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        administrateur.mot_de_passe = make_password(serializer.validated_data['nouveau_mot_de_passe'])
        administrateur.save()
        
        return Response(
            {'message': 'Mot de passe changé avec succès.'},
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['post'])
    def desactiver(self, request, id_admin=None):
        administrateur = self.get_object()
        
        if administrateur.status == 'inactif':
            return Response(
                {'message': 'Cet administrateur est déjà inactif.'},
                status=status.HTTP_200_OK
            )
        
        # Vérifie uniquement si c'est un superadmin
        if administrateur.role == 'superadmin':
            # Compte combien de superadmins actifs il reste
            superadmins_actifs = Administrateur.objects.filter(
                status='actif',
                role='superadmin'
            ).count()
            
            if superadmins_actifs <= 1:
                return Response(
                    {'error': 'Impossible de désactiver le dernier superadmin actif.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        administrateur.status = 'inactif'
        administrateur.save()
        
        return Response(
            {
                'message': 'Administrateur désactivé avec succès.',
                'administrateur': AdministrateurListSerializer(administrateur).data
            },
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['post'])
    def activer(self, request, id_admin=None):
        administrateur = self.get_object()
        
        if administrateur.status == 'actif':
            return Response(
                {'message': 'Cet administrateur est déjà actif.'},
                status=status.HTTP_200_OK
            )
        
        administrateur.status = 'actif'
        administrateur.save()
        
        return Response(
            {
                'message': 'Administrateur activé avec succès.',
                'administrateur': AdministrateurListSerializer(administrateur).data
            },
            status=status.HTTP_200_OK
        )