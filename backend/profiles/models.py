from django.db import models
from django.contrib.auth.models import User

class PatientProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    first_name = models.CharField(max_length=30, blank=True, null=True)  
    last_name = models.CharField(max_length=30, blank=True, null=True)
    medical_history = models.TextField(null=True, blank=True)

    def __str__(self):
        return f"Patient: {self.first_name} {self.last_name} ({self.user.email})"
    
class DoctorProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    first_name = models.CharField(max_length=30, blank=True, null=True)
    last_name = models.CharField(max_length=30, blank=True, null=True)
    specialization = models.CharField(max_length=255)

    def __str__(self):
        return f"Doctor: {self.first_name} {self.last_name} - {self.specialization}"
