from django.urls import path, include

urlpatterns = [
    # Authentification
    path('auth/', include('tickets.urls.auth_urls')),
    
    # Gestion des utilisateurs
    path('', include('tickets.urls.utilisateur_urls')),
    
    # Gestion des administrateurs
    path('', include('tickets.urls.admin_urls')),
    
    # Gestion des événements
    path('', include('tickets.urls.evenement_urls')),
    
    # Gestion des tickets
    path('', include('tickets.urls.ticket_urls')),
    
    # Gestion des achats
    path('', include('tickets.urls.achat_urls')),
    
    # Gestion des favoris
    path('', include('tickets.urls.favori_urls')),
    
    # AI Recommendations
    path('ai/', include('tickets.urls.ai_urls')),
    
    # Gestion des transactions
    path('', include('tickets.urls.transaction_urls')),
]