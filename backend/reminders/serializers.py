from rest_framework import serializers
from .models import DailyReminder

class DailyReminderSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyReminder
        fields = ['id', 'reminder_type', 'reminder_time', 'medication_name', 'active']
    
    def validate(self, data):
        reminder_type = data.get('reminder_type')
        medication_name = data.get('medication_name')

        if reminder_type == 'medication':
            if not medication_name or medication_name.strip() == '':
                raise serializers.ValidationError({
                    'medication_name': 'Medication name is required for medication reminders.'
                })
        else:
            if medication_name:
                raise serializers.ValidationError({
                    'medication_name': 'Medication name should only be provided for medication reminders.'
                })

        return data