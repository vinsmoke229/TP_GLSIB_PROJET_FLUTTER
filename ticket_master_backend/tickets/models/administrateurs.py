from django.db import models

class Administrateur(models.Model):
    id_admin = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    mot_de_passe = models.CharField(max_length=255)
    status = models.CharField(max_length=50, default='actif')
    role = models.CharField(max_length=50)
    photo_profil = models.ImageField(upload_to='administrateurs/', blank=True, null=True)

    @property
    def is_authenticated(self):
        """DRF requirement: Return True for authenticated admins."""
        return True

    @property
    def is_anonymous(self):
        """DRF requirement: Return False for authenticated admins."""
        return False

    def __str__(self):
        return f"{self.prenom} {self.nom}"