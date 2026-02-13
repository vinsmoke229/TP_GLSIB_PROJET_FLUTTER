from django.db import models
from .evenements import Evenement


class Session(models.Model):
    """Modèle pour les sessions d'événements (date/heure spécifiques)"""
    id_session = models.AutoField(primary_key=True)
    evenement = models.ForeignKey(Evenement, on_delete=models.CASCADE, related_name='sessions')
    date_heure = models.DateTimeField(null=False, blank=False)
    
    class Meta:
        ordering = ['date_heure']  # Sessions triées par date/heure
        unique_together = ('evenement', 'date_heure')  # Pas de doublons
    
    def __str__(self):
        return f"{self.evenement.titre_evenement} - {self.date_heure.strftime('%d/%m/%Y %H:%M')}"
