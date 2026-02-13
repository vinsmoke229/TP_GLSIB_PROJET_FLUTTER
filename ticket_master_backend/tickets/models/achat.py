from django.db import models
from .session import Session
import uuid

class Achat(models.Model):
    id_achat = models.AutoField(primary_key=True)
    id_utilisateur = models.ForeignKey('Utilisateur', on_delete=models.CASCADE)
    id_ticket = models.ForeignKey('Ticket', on_delete=models.CASCADE)
    session = models.ForeignKey(Session, on_delete=models.SET_NULL, null=True, blank=True, related_name='achats')
    quantite = models.IntegerField()
    montant_total = models.DecimalField(max_digits=10, decimal_places=2)
    date_achat = models.DateTimeField(auto_now_add=True)
    est_utilise = models.BooleanField(default=False)
    date_utilisation = models.DateTimeField(null=True, blank=True, help_text="Date et heure de validation du ticket")
    
    # Champs pour le QR code
    code_qr = models.CharField(max_length=255, unique=True, null=True, blank=True, 
                                help_text="Code unique UUID pour le QR")
    qr_image = models.ImageField(upload_to='qr_codes/', null=True, blank=True,
                                  help_text="Image PNG du QR code")

    def __str__(self):
        return f"Achat {self.id_achat} - Utilisateur {self.id_utilisateur} - Ticket {self.id_ticket}"
    
    def save(self, *args, **kwargs):
        # Générer un code QR unique UUID si pas déjà présent
        if not self.code_qr:
            self.code_qr = str(uuid.uuid4())
        super().save(*args, **kwargs)