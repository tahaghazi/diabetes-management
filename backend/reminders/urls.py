from django.urls import path
from . import views

urlpatterns = [
    path('create-reminder/', views.create_daily_reminder, name='create_daily_reminder'),
    path('get-reminders/', views.get_daily_reminders, name='get_daily_reminders'),
]
