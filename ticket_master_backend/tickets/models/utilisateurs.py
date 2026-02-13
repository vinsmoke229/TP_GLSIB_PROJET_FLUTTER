from django.db import models

class Utilisateur(models.Model):
    id_utilisateur = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=100, null=False, blank=False)
    prenom = models.CharField(max_length=100, null=False, blank=False)
    email = models.EmailField(unique=True, null=False, blank=False)
    adresse = models.CharField(max_length=255, null=True, blank=True)
    mot_de_passe = models.CharField(max_length=255, null=False, blank=False)
    statut = models.CharField(max_length=50, default='actif')
    tel = models.CharField(max_length=100, null=False, blank=False)  
    solde = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    interests = models.TextField(blank=True, default='', help_text='Comma-separated interests (e.g., Music,Tech,Art)')
    
    # Web / Admin Fields
    photo_profil = models.ImageField(upload_to='utilisateurs/', blank=True, null=True)
    last_login = models.DateTimeField(null=True, blank=True)
    nom_utilisateur = models.CharField(max_length=150, unique=True, null=True, blank=True)
    total_code_use = models.IntegerField(default=0)
    code_parrainage = models.CharField(max_length=50, unique=True, null=True, blank=True)

    @property
    def is_authenticated(self):
        """DRF requirement: Return True for authenticated users."""
        return True

    @property
    def is_anonymous(self):
        """DRF requirement: Return False for authenticated users."""
        return False

    def __str__(self):
        return f"{self.prenom} {self.nom} (Solde: {self.solde})"
