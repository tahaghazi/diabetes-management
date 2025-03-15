from .serializers import UserRegisterSerializer, UserLoginSerializer
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import login, logout

@api_view(['POST'])
def user_register(request):
    serializer = UserRegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        return Response({
            "message": "User registered successfully!",
            "user": {
                "id": user.id,
                "email": user.email
            }
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def user_login(request):
    serializer = UserLoginSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.validated_data['user']
        login(request, user)

        account_type = "unknown"
        if hasattr(user, 'patientprofile'):
            account_type = 'patient'
        elif hasattr(user, 'doctorprofile'):
            account_type = 'doctor'

        return Response({
            "message": "Login successful!",
            "user": {
                "id": user.id,
                "email": user.email,
                "account_type": account_type
            }
        }, status=status.HTTP_200_OK)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def user_logout(request):
    logout(request)
    response = Response({"message": "Logout Successful!"}, status=status.HTTP_200_OK)
    response.delete_cookie("sessionid")
    response.delete_cookie("csrftoken")
    return response
