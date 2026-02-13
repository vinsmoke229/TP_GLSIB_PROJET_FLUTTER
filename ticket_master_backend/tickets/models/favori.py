from django.db import models
from .utilisateurs import Utilisateur
from .evenements import Evenement


class Favori(models.Model):
    """Modèle pour stocker les événements favorisés par les utilisateurs"""
    id_favori = models.AutoField(primary_key=True)
    utilisateur = models.ForeignKey(Utilisateur, on_delete=models.CASCADE, related_name='favoris')
    evenement = models.ForeignKey(Evenement, on_delete=models.CASCADE, related_name='favoris_utilisateurs')
    date_ajout = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('utilisateur', 'evenement')  # Un utilisateur ne peut pas favoriser deux fois le même événement
        ordering = ['-date_ajout']  # Les plus récents en premier
    
    def __str__(self):
        return f"{self.utilisateur.prenom} {self.utilisateur.nom} - {self.evenement.titre_evenement}"
