from django.db import models
from .utilisateurs import Utilisateur
import uuid

class Transaction(models.Model):
    TYPE_CHOICES = [
        ('depot', 'Dépôt'),
        ('achat', 'Achat de ticket'),
        ('bonus_parrainage', 'Bonus parrainage'),
    ]
    
    MOYEN_PAIEMENT_CHOICES = [
        ('mobile_money', 'Mobile Money'),
        ('carte_bancaire', 'Carte Bancaire'),
        ('especes', 'Espèces'),
    ]
    
    id_transaction = models.AutoField(primary_key=True)
    id_utilisateur = models.ForeignKey(
        Utilisateur, 
        on_delete=models.CASCADE,
        related_name='transactions'
    )
    montant = models.DecimalField(max_digits=10, decimal_places=2)
    type_transaction = models.CharField(max_length=50, choices=TYPE_CHOICES)
    date_transaction = models.DateTimeField(auto_now_add=True)
    reference = models.CharField(max_length=100, unique=True, blank=True)
    
    id_achat = models.OneToOneField(
        'Achat', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='transaction'
    )
    moyen_paiement = models.CharField(
        max_length=50, 
        blank=True, 
        null=True,
        choices=MOYEN_PAIEMENT_CHOICES
    )
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Description ou note sur la transaction"
    )
    
    def save(self, *args, **kwargs):
        if not self.reference:
            prefix = self.type_transaction.upper()[:3]
            self.reference = f"{prefix}-{uuid.uuid4().hex[:10].upper()}"
        super().save(*args, **kwargs)
    
    def __str__(self):
        signe = "+" if self.type_transaction in ['depot', 'bonus_parrainage'] else "-"
        return f"{self.reference} | {signe}{self.montant} FCFA | {self.get_type_transaction_display()}"
    
    class Meta:
        ordering = ['-date_transaction']
        verbose_name = "Transaction"
        verbose_name_plural = "Transactions"