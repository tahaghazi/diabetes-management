from django.db import models
from django.contrib.auth.models import User

class DailyReminder(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    reminder_type = models.CharField(max_length=100, choices=[
        ('blood_glucose_test', 'Blood Glucose Test'),
        ('medication', 'Medication'),
        ('hydration', 'Hydration')
    ])
    reminder_time = models.TimeField()
    active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.get_reminder_type_display()} Reminder for {self.user.username}"
