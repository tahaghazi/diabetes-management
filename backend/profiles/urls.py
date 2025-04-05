from django.urls import path
from .views import update_profile

urlpatterns = [
    path('update-profile/', update_profile, name="update-profile"),
]
