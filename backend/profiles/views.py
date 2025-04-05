from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from .serializers import PatientProfileUpdateSerializer, DoctorProfileUpdateSerializer
from rest_framework.permissions import IsAuthenticated

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    user = request.user

    if hasattr(user, 'patientprofile'):
        profile = user.patientprofile
        serializer = PatientProfileUpdateSerializer(profile, data=request.data, partial=True)
    elif hasattr(user, 'doctorprofile'):
        profile = user.doctorprofile
        serializer = DoctorProfileUpdateSerializer(profile, data=request.data, partial=True)
    else:
        return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)
    
    if serializer.is_valid():
        serializer.save()
        return Response({
            "message": "Profile updated successfully!",
            "data": serializer.data
        }, status=status.HTTP_200_OK)
    
    return Response({
        "message": "Invalid data",
        "errors": serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)
