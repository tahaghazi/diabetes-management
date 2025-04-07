from django.core.mail import send_mail
from django.contrib.auth import get_user_model
from django.conf import settings
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .serializers import UserRegisterSerializer, UserLoginSerializer
from rest_framework_simplejwt.tokens import RefreshToken
import random
import string
from .models import OTP

def generate_otp():
    return ''.join(random.choices(string.digits, k=6))

User = get_user_model()

@api_view(['POST'])
def user_register(request):
    serializer = UserRegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        profile = user.patientprofile if hasattr(user, 'patientprofile') else user.doctorprofile
     
        refresh = RefreshToken.for_user(user)
        access_token = str(refresh.access_token)
        refresh_token = str(refresh)

        return Response({
            "message": "User registered successfully!",
            "user": {
                "id": user.id,
                "email": user.email,
                "first_name": profile.first_name,
                "last_name": profile.last_name,
                "account_type": request.data['account_type']
            },
            "refresh": refresh_token,
            "access": access_token
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def user_login(request):
    serializer = UserLoginSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.validated_data['user']
        refresh = serializer.validated_data['refresh']
        access = serializer.validated_data['access']

        account_type = serializer.validated_data['account_type']
        first_name = ""
        last_name = ""
        specialization = ""
        medical_history = ""  
        if account_type == 'patient':
            first_name = user.patientprofile.first_name
            last_name = user.patientprofile.last_name
            medical_history = user.patientprofile.medical_history or ""  
        elif account_type == 'doctor':
            first_name = user.doctorprofile.first_name
            last_name = user.doctorprofile.last_name
            specialization = user.doctorprofile.specialization

        response_data = {
            "message": "Login successful!",
            "refresh": refresh, 
            "access": access,    
            "user": {
                "id": user.id,
                "email": user.email,
                "first_name": first_name,
                "last_name": last_name,
                "account_type": account_type
            }
        }
        if account_type == 'doctor':
            response_data['user']['specialization'] = specialization
        if account_type == 'patient':
            response_data['user']['medical_history'] = medical_history  

        return Response(response_data, status=status.HTTP_200_OK, content_type='application/json; charset=utf-8')
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def user_logout(request):
    return Response({"message": "Logout Successful!"}, status=status.HTTP_200_OK)

@api_view(['POST'])
def send_reset_password_email(request):
    email = request.data.get('email')
    
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"error": "No user found with this email"}, status=status.HTTP_404_NOT_FOUND)
    
    otp = generate_otp()

    OTP.objects.filter(email=email).delete()

    otp_instance = OTP(email=email, otp=otp)
    otp_instance.save()

    send_mail(
        subject="Reset Your Password",
        message=f"Your OTP to reset your password is: {otp}\nThis OTP is valid for 10 minutes.",
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[email],
        fail_silently=False,
    )

    return Response({"message": "OTP sent successfully!"}, status=status.HTTP_200_OK)

@api_view(['POST'])
def reset_password_confirm(request):
    otp = request.data.get('otp')
    new_password = request.data.get('new_password')
    confirm_new_password = request.data.get('confirm_new_password')

    if not otp or not new_password or not confirm_new_password:
        return Response({"error": "OTP, new password, and confirmation are required"}, status=status.HTTP_400_BAD_REQUEST)

    if new_password != confirm_new_password:
        return Response({"error": "Passwords do not match"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        otp_instance = OTP.objects.get(otp=otp)
    except OTP.DoesNotExist:
        return Response({"error": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST)

    if otp_instance.is_expired():
        return Response({"error": "OTP has expired"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=otp_instance.email)
    except User.DoesNotExist:
        return Response({"error": "No user found with this email"}, status=status.HTTP_404_NOT_FOUND)

    user.set_password(new_password)
    user.save()

    otp_instance.delete()
    
    return Response({"message": "Password reset successfully!"}, status=status.HTTP_200_OK)
