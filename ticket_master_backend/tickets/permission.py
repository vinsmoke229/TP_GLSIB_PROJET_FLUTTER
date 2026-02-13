from rest_framework.permissions import BasePermission
from django.contrib.auth.models import AnonymousUser
from .models.administrateurs import Administrateur
from .models.utilisateurs import Utilisateur
class IsAdministrateur(BasePermission):
    def has_permission(self, request, view):
        if not request.user or isinstance(request.user, AnonymousUser):
            return False
        return isinstance(request.user, Administrateur)
          


class IsUtilisateur(BasePermission):
    def has_permission(self, request, view):
        if not request.user or isinstance(request.user, AnonymousUser):
            return False
        return isinstance(request.user, Utilisateur)



