from django.contrib import admin
from django import forms
from .models import DailyReminder

@admin.register(DailyReminder)
class DailyReminderAdmin(admin.ModelAdmin):
    list_display = ('user', 'reminder_type', 'reminder_time', 'medication_name', 'active')  
    list_filter = ('user', 'reminder_type', 'active')
    search_fields = ('user__username', 'reminder_type', 'medication_name')
    ordering = ('reminder_time',)  
    actions = ['make_active', 'make_inactive']

    fieldsets = (
        (None, {
            'fields': ('user', 'reminder_type', 'reminder_time', 'medication_name', 'active')  
        }),
    )

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')

    def make_active(self, request, queryset):
        queryset.update(active=True)
        self.message_user(request, "تم تفعيل التذكيرات المحددة")
    make_active.short_description = "تفعيل التذكيرات المحددة"

    def make_inactive(self, request, queryset):
        queryset.update(active=False)
        self.message_user(request, "تم تعطيل التذكيرات المحددة")
    make_inactive.short_description = "تعطيل التذكيرات المحددة"

    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        
        class CustomForm(form):
            def clean(self):
                cleaned_data = super().clean()
                reminder_type = cleaned_data.get('reminder_type')
                medication_name = cleaned_data.get('medication_name')

                if reminder_type == 'medication':
                    if not medication_name or medication_name.strip() == '':
                        raise forms.ValidationError({
                            'medication_name': 'اسم الدواء مطلوب لتذكيرات الأدوية.'
                        })
                else:
                    if medication_name:
                        raise forms.ValidationError({
                            'medication_name': 'اسم الدواء يجب أن يكون فارغًا للتذكيرات غير الأدوية.'
                        })
                return cleaned_data

        return CustomForm