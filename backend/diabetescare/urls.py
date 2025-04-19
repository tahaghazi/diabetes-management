from django.urls import path
from . import views

urlpatterns = [
    path('predict/', views.predict_diabetes, name='predict_diabetes'),
    path('glucose/add/', views.add_glucose_reading, name='add_glucose_reading'),
    path('glucose/list/', views.list_glucose_readings, name='add_glucose_reading'),
    path('alternative-medicine/', views.alternative_medicines, name='alternative_medicines'),
]