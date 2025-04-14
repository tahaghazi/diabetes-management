from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .serializers import GlucoseTrackingSerializer
from profiles.models import PatientProfile

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_glucose_reading(request):
    user = request.user

    try:
        patient = PatientProfile.objects.get(user=user)
    except PatientProfile.DoesNotExist:
        return Response({"error": "Only patients can add glucose readings."}, status=status.HTTP_403_FORBIDDEN)

    serializer = GlucoseTrackingSerializer(data=request.data)
    if serializer.is_valid():
        glucose_reading = serializer.save(patient=patient)

        medical_history_entry = (
            f"{glucose_reading.get_glucose_type_display()}: {glucose_reading.glucose_value} mg/dL "
            f"on {glucose_reading.timestamp.strftime('%Y-%m-%d %H:%M')}"
        )
        if patient.medical_history:
            patient.medical_history += f"\n{medical_history_entry}"
        else:
            patient.medical_history = medical_history_entry
        patient.save()

        return Response({
            "message": "Glucose reading added successfully!",
            "data": serializer.data
        }, status=status.HTTP_201_CREATED)

    return Response({
        "message": "Invalid data",
        "errors": serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)