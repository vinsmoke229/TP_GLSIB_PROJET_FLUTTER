from django.urls import path, include
from rest_framework.routers import DefaultRouter
from ..views.gestion_transaction import TransactionViewSet

router = DefaultRouter()
router.register(r'transactions', TransactionViewSet, basename='transaction')

urlpatterns = router.urls
