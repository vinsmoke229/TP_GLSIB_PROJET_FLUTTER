"""
Utilitaires de géocodage pour convertir des adresses en coordonnées GPS
"""
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderServiceError
import time
import uuid


def geocode_address(address, retries=3):
    if not address or not address.strip():
        return None, None
    
    # User agent unique pour éviter les blocages
    unique_id = str(uuid.uuid4())[:8]
    user_agent = f"TicketBackendApp_{unique_id}"
    
    for attempt in range(retries):
        try:
            # Initialiser le géocodeur Nominatim (OpenStreetMap)
            geolocator = Nominatim(user_agent=user_agent, timeout=15)
            
            # Ajouter un délai progressif pour respecter les limites de taux
            time.sleep(1.5 * (attempt + 1))
            
            # Effectuer le géocodage
            location = geolocator.geocode(address)
            
            if location:
                return location.latitude, location.longitude
            else:
                return None, None
                
        except GeocoderTimedOut:
            if attempt == retries - 1:
                return None, None
            
        except GeocoderServiceError as e:
            if attempt == retries - 1:
                return None, None
            time.sleep(3)  # Attendre plus longtemps en cas d'erreur 509
            
        except Exception as e:
            return None, None
    
    return None, None


def reverse_geocode(latitude, longitude):
    if latitude is None or longitude is None:
        return None
    
    try:
        geolocator = Nominatim(user_agent="ticket_backend_app", timeout=10)
        time.sleep(1)
        
        location = geolocator.reverse(f"{latitude}, {longitude}")
        
        if location:
            return location.address
        else:
            return None
            
    except Exception as e:
        return None
