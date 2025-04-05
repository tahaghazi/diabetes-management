from rest_framework import serializers
from .models import PatientProfile, DoctorProfile

class PatientProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientProfile
        fields = ['first_name', 'last_name', 'medical_history']

    def validate_first_name(self, value):
        if not value.isalpha():
            raise serializers.ValidationError("First name should only contain letters.")
        return value

    def validate_last_name(self, value):
        if not value.isalpha():
            raise serializers.ValidationError("Last name should only contain letters.")
        return value

class DoctorProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorProfile
        fields = ['first_name', 'last_name', 'specialization']

    def validate_specialization(self, value):
        if len(value) < 3:
            raise serializers.ValidationError("Specialization name should be at least 3 characters long.")
        return value

    def validate_first_name(self, value):
        if not value.isalpha():
            raise serializers.ValidationError("First name should only contain letters.")
        return value

    def validate_last_name(self, value):
        if not value.isalpha():
            raise serializers.ValidationError("Last name should only contain letters.")
        return value
