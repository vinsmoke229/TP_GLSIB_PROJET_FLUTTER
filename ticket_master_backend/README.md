# Ticket Backend API

API REST pour la gestion de tickets d'événements avec Django REST Framework.


**Prérequis :** Docker et Docker Compose installés

```bash
# 1. Cloner le projet
git clone <votre-repo>
cd Ticketbackend

# 2. Démarrer avec Docker
docker-compose up --build

# 4. Accéder à l'API
# http://localhost:8000
```
**Aucune installation de Python, PostgreSQL ou dépendances nécessaire !**

### Option 2 : Installation locale (Pour développement avancé)

**Prérequis :** Python 3.11+, PostgreSQL 15+

```bash
# 1. Créer environnement virtuel
python -m venv venv
venv\Scripts\activate 

# 2. Installer dépendances
pip install -r requirements.txt

# 3. Configurer la base de données
# Créer une BDD PostgreSQL nommée 'ticket_db'
# Copier .env.example vers .env et ajuster les valeurs

# 4. Migrations
python manage.py migrate

# 6. Lancer le serveur
python manage.py runserver
```

## Commandes utiles

### Avec Docker

```bash
# Voir les logs
docker-compose logs -f

# Voir les logs d'un service spécifique
docker-compose logs -f web

# Arrêter les conteneurs
docker-compose down

# Arrêter et supprimer les volumes (supprime la BDD)
docker-compose down -v

# Exécuter des commandes Django
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py makemigrations
docker-compose exec web python manage.py shell

# Reconstruire après modification du Dockerfile
docker-compose build --no-cache
docker-compose up
```
- **Backend:** Django 6.0, Django REST Framework
- **Base de données:** PostgreSQL 15
- **Authentification:** JWT (PyJWT)
- **Containerisation:** Docker & Docker Compose
- **Langage:** Python 3.11