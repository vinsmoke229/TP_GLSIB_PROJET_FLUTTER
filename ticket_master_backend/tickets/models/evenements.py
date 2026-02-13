from django.db import models

class Evenement(models.Model):
    id_evenement = models.AutoField(primary_key=True)
    titre_evenement = models.CharField(max_length=100,null=False,blank=False)
    date = models.DateField(null=False,blank=False)
    lieu = models.CharField(max_length=100,null=False,blank=False)
    image = models.ImageField(upload_to='evenements/', blank=True, null=True)
    type_evenement = models.CharField(max_length=200, null=False)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    heure_debut = models.TimeField(null=True, blank=True)
    heure_fin = models.TimeField(null=True, blank=True)

    def __str__(self):
        return self.titre_evenement