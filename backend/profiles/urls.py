from django.urls import path
from .views import (
    update_profile, 
    search_doctors, 
    link_patient_to_doctor, 
    unlink_from_doctor
)

urlpatterns = [
    path('update-profile/', update_profile, name="update-profile"),
    path('search-doctors/', search_doctors, name="search-doctors"),
    path('link-to-doctor/', link_patient_to_doctor, name="link-to-doctor"),
    path('unlink-from-doctor/', unlink_from_doctor, name='unlink-from-doctor'),
]