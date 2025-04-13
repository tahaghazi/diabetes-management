from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import DailyReminder
from .serializers import DailyReminderSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_daily_reminder(request):
    user = request.user
    if not hasattr(user, 'patientprofile'):
        return Response({"error": "Only patients can create reminders"}, status=status.HTTP_403_FORBIDDEN)

    try:
        data = request.data
        serializer = DailyReminderSerializer(data=data)
        if serializer.is_valid():
            serializer.save(user=user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_daily_reminders(request):
    user = request.user  
    if not hasattr(user, 'patientprofile'):
        return Response({"error": "Only patients can view reminders"}, status=status.HTTP_403_FORBIDDEN)

    reminders = DailyReminder.objects.filter(user=user, active=True)  
    serializer = DailyReminderSerializer(reminders, many=True)  
    return Response(serializer.data) 

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_daily_reminder(request, reminder_id):
    user = request.user
    if not hasattr(user, 'patientprofile'):
        return Response({"error": "Only patients can update reminders"}, status=status.HTTP_403_FORBIDDEN)

    try:
        reminder = DailyReminder.objects.get(id=reminder_id, user=user)
        serializer = DailyReminderSerializer(reminder, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except DailyReminder.DoesNotExist:
        return Response({"error": "Reminder not found"}, status=status.HTTP_404_NOT_FOUND)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_daily_reminder(request, reminder_id):
    user = request.user
    if not hasattr(user, 'patientprofile'):
        return Response({"error": "Only patients can delete reminders"}, status=status.HTTP_403_FORBIDDEN)

    try:
        reminder = DailyReminder.objects.get(id=reminder_id, user=user)
        reminder.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    except DailyReminder.DoesNotExist:
        return Response({"error": "Reminder not found"}, status=status.HTTP_404_NOT_FOUND)