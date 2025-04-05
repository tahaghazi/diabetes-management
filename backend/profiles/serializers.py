from rest_framework import serializers
from .models import PatientProfile, DoctorProfile

class PatientProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientProfile
        fields = ['first_name', 'last_name', 'medical_history']

class DoctorProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorProfile
        fields = ['first_name', 'last_name', 'specialization']