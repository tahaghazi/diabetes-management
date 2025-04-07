from django.urls import path
from . import views

urlpatterns = [
    path('create-reminder/', views.create_daily_reminder, name='create_daily_reminder'),
    path('get-reminders/', views.get_daily_reminders, name='get_daily_reminders'),
    path('update-reminder/<int:reminder_id>/', views.update_daily_reminder, name='update_daily_reminder'),
    path('delete-reminder/<int:reminder_id>/', views.delete_daily_reminder, name='delete_daily_reminder'),
]
