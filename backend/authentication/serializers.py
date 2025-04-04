from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from profiles.models import PatientProfile, DoctorProfile

class UserRegisterSerializer(serializers.ModelSerializer):
    password1 = serializers.CharField(write_only=True, min_length=8)
    password2 = serializers.CharField(write_only=True, min_length=8)
    account_type = serializers.ChoiceField(choices=[('patient', 'Patient'), ('doctor', 'Doctor')])
    first_name = serializers.CharField(max_length=100)  
    last_name = serializers.CharField(max_length=100)   
    specialization = serializers.CharField(max_length=100, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ['email', 'password1', 'password2', 'account_type', 'first_name', 'last_name', 'specialization']

    def validate(self, data):
        data['email'] = data['email'].lower()  
        if data['password1'] != data['password2']:
            raise serializers.ValidationError({"password": "Passwords must match."})
        
        if User.objects.filter(email=data['email']).exists():
            raise serializers.ValidationError({"email": "This email is already in use."})
        
        if data['account_type'] == 'doctor' and not data.get('specialization'):
            raise serializers.ValidationError({"specialization": "Specialization is required for doctors."})

        return data

    def create(self, validated_data):
        validated_data.pop('password2')
        account_type = validated_data.pop('account_type')
        first_name = validated_data.pop('first_name')  
        last_name = validated_data.pop('last_name')   
        specialization = validated_data.pop('specialization', '') 
        
        user = User.objects.create_user(
            username=validated_data['email'], 
            email=validated_data['email'],
            password=validated_data['password1']
        )
        
        if account_type == 'patient':
            PatientProfile.objects.create(user=user, first_name=first_name, last_name=last_name)
        elif account_type == 'doctor':
            DoctorProfile.objects.create(user=user, first_name=first_name, last_name=last_name, specialization=specialization)

        return user

class UserLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        email = data.get('email').lower()  
        password = data.get('password')

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise serializers.ValidationError({"error": "Invalid email or password."})

        user = authenticate(username=user.username, password=password)  
        if not user:
            raise serializers.ValidationError({"error": "Invalid email or password."})
        
        if hasattr(user, 'patientprofile'):
            account_type = 'patient'
        elif hasattr(user, 'doctorprofile'):
            account_type = 'doctor'
        else:
            raise serializers.ValidationError({"error": "User profile is not set correctly."})

        data['user'] = user
        data['account_type'] = account_type
        
        return data