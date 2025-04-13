from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth.models import User
from .serializers import (
    PatientProfileUpdateSerializer, 
    DoctorProfileUpdateSerializer,
    DoctorSerializer
)
from .models import DoctorPatientRelation

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    user = request.user

    try:
        if hasattr(user, 'patientprofile'):
            profile = user.patientprofile
            serializer = PatientProfileUpdateSerializer(profile, data=request.data, partial=True)
            profile_type = "patient"
        elif hasattr(user, 'doctorprofile'):
            profile = user.doctorprofile
            serializer = DoctorProfileUpdateSerializer(profile, data=request.data, partial=True)
            profile_type = "doctor"
        else:
            return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                "message": f"{profile_type.capitalize()} profile updated successfully!",
                "data": serializer.data
            }, status=status.HTTP_200_OK)
        
        return Response({
            "message": "Invalid data",
            "errors": serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        return Response({
            "error": f"An error occurred: {str(e)}"
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_doctors(request):
    user = request.user
    if not hasattr(user, 'patientprofile'):
        return Response({"error": "Only patients can search for doctors"}, status=status.HTTP_403_FORBIDDEN)

    query = request.GET.get('query', '')
    doctors = User.objects.filter(
        doctorprofile__isnull=False, 
        first_name__icontains=query
    ) | User.objects.filter(
        doctorprofile__isnull=False,
        last_name__icontains=query
    ) | User.objects.filter(
        doctorprofile__isnull=False,
        doctorprofile__specialization__icontains=query
    )

    serializer = DoctorSerializer(doctors, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def link_patient_to_doctor(request):
    user = request.user
    if not hasattr(user, 'patientprofile'):
        return Response({"error": "Only patients can link to a doctor"}, status=status.HTTP_403_FORBIDDEN)

    doctor_id = request.data.get('doctor_id')
    if not doctor_id:
        return Response({"error": "Doctor ID is required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        doctor = User.objects.get(id=doctor_id, doctorprofile__isnull=False)
        if DoctorPatientRelation.objects.filter(doctor=doctor, patient=user).exists():
            return Response({"error": "You are already linked to this doctor"}, status=status.HTTP_400_BAD_REQUEST)

        relation = DoctorPatientRelation(doctor=doctor, patient=user)
        relation.save()
        return Response({"message": "Successfully linked to the doctor"}, status=status.HTTP_201_CREATED)
    except User.DoesNotExist:
        return Response({"error": "Doctor not found"}, status=status.HTTP_404_NOT_FOUND)