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
    data = request.data  
    
    serializer = DailyReminderSerializer(data=data)
    
    if serializer.is_valid(): 
        reminder = serializer.save(user=user)  
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_daily_reminders(request):
    user = request.user  
    reminders = DailyReminder.objects.filter(user=user, active=True)  
    serializer = DailyReminderSerializer(reminders, many=True)  
    return Response(serializer.data) 
