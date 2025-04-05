from rest_framework import serializers
from .models import DailyReminder

class DailyReminderSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyReminder
        fields = ['reminder_type', 'reminder_time', 'active']