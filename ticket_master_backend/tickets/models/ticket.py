from django.db import models

class Ticket(models.Model):
    id_ticket = models.AutoField(primary_key=True)
    type = models.CharField(max_length=100)
    prix = models.DecimalField(max_digits=10, decimal_places=2)
    date_creation = models.DateTimeField(auto_now_add=True)
    stock = models.IntegerField()
    id_evenement = models.ForeignKey('Evenement', on_delete=models.CASCADE)

    def __str__(self):
        return f"Ticket {self.id_ticket} - {self.type}"
