from rest_framework import serializers
from django.contrib.auth.models import User
from .models import PatientProfile, DoctorProfile, DoctorPatientRelation

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

class DoctorSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(source='doctorprofile.first_name')
    last_name = serializers.CharField(source='doctorprofile.last_name')
    specialization = serializers.CharField(source='doctorprofile.specialization')

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'specialization']

class DoctorPatientRelationSerializer(serializers.ModelSerializer):
    doctor = DoctorSerializer()

    class Meta:
        model = DoctorPatientRelation
        fields = ['id', 'doctor']

class PatientProfileSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(source='patientprofile.first_name')
    last_name = serializers.CharField(source='patientprofile.last_name')
    medical_history = serializers.CharField(source='patientprofile.medical_history', allow_null=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'medical_history']

