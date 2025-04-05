from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from .serializers import PatientProfileUpdateSerializer, DoctorProfileUpdateSerializer
from rest_framework.permissions import IsAuthenticated

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