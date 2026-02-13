"""
Utilitaire de génération de QR codes pour les achats de tickets
"""
import qrcode
from io import BytesIO
from django.core.files import File
from django.conf import settings


def generate_qr_code(achat, request=None):
  
    if request:
        base_url = request.build_absolute_uri('/')[:-1]
    else:
        # Fallback si pas de request
        base_url = getattr(settings, 'SITE_URL', 'http://0.0.0.0:8000')
    
 
    verification_url = f"{base_url}/api/achats/scan/{achat.code_qr}/"
    
    qr = qrcode.QRCode(
        version=1,  
        error_correction=qrcode.constants.ERROR_CORRECT_H,  # Haute correction d'erreur
        box_size=10, 
        border=4,
    )
    qr.add_data(verification_url)
    qr.make(fit=True)
    
    # Générer l'image du QR code
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Sauvegarder dans un buffer en mémoire
    buffer = BytesIO()
    img.save(buffer, format='PNG')
    buffer.seek(0)
    
    # Créer un fichier Django à partir du buffer
    filename = f'qr_{achat.code_qr}.png'
    achat.qr_image.save(filename, File(buffer), save=False)
    
    return achat


def get_qr_url(achat, request=None):
    if not achat.qr_image:
        return None
    
    if request:
        return request.build_absolute_uri(achat.qr_image.url)
    
    return achat.qr_image.url
