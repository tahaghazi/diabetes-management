from django.contrib import admin
from .models import DailyReminder

@admin.register(DailyReminder)
class DailyReminderAdmin(admin.ModelAdmin):
    list_display = ('user', 'reminder_type', 'reminder_time', 'active')  
    list_filter = ('user', 'reminder_type', 'active')
    search_fields = ('user__username', 'reminder_type')
    ordering = ('reminder_time',)  
    actions = ['make_active', 'make_inactive']

    fieldsets = (
        (None, {
            'fields': ('user', 'reminder_type', 'reminder_time', 'active')
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