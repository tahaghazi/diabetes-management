from django.contrib import admin
from django.urls import reverse
from django.utils.html import format_html
from .models import PatientProfile, DoctorProfile, DoctorPatientRelation
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError

class DoctorPatientRelationInlineAsDoctor(admin.TabularInline):
    model = DoctorPatientRelation
    fk_name = 'doctor'
    extra = 0
    verbose_name = "Patient"
    verbose_name_plural = "Patients Linked to This Doctor"
    
    def patient_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.patient.id])
        return format_html('<a href="{}">{}</a>', url, obj.patient)
    
    patient_link.short_description = "Patient"
    
    fields = ('patient_link',)
    readonly_fields = ('patient_link',)

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == 'patient':
            kwargs['queryset'] = User.objects.filter(patientprofile__isnull=False)
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

class DoctorPatientRelationInlineAsPatient(admin.TabularInline):
    model = DoctorPatientRelation
    fk_name = 'patient'
    extra = 0
    verbose_name = "Doctor"
    verbose_name_plural = "Doctors Linked to This Patient"
    
    def doctor_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.doctor.id])
        return format_html('<a href="{}">{}</a>', url, obj.doctor)
    
    doctor_link.short_description = "Doctor"
    
    fields = ('doctor_link',)
    readonly_fields = ('doctor_link',)

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == 'doctor':
            kwargs['queryset'] = User.objects.filter(doctorprofile__isnull=False)
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

class PatientProfileAdmin(admin.ModelAdmin):
    list_display = ['user_link', 'first_name', 'last_name', 'medical_history', 'doctors_link']
    search_fields = ['user__email', 'first_name', 'last_name']
    list_filter = ['first_name', 'last_name']

    def user_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.user.id])
        return format_html('<a href="{}">{}</a>', url, obj.user.email)
    
    user_link.short_description = "User"
    user_link.admin_order_field = 'user__email'

    def doctors_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.user.id])
        return format_html('<a href="{}">View Doctors</a>', url)
    
    doctors_link.short_description = "Doctors"

class DoctorProfileAdmin(admin.ModelAdmin):
    list_display = ['user_link', 'first_name', 'last_name', 'specialization', 'patients_link']
    search_fields = ['user__email', 'first_name', 'last_name', 'specialization']
    list_filter = ['specialization', 'first_name', 'last_name']

    def user_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.user.id])
        return format_html('<a href="{}">{}</a>', url, obj.user.email)
    
    user_link.short_description = "User"
    user_link.admin_order_field = 'user__email'

    def patients_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.user.id])
        return format_html('<a href="{}">View Patients</a>', url)
    
    patients_link.short_description = "Patients"

class DoctorPatientRelationAdmin(admin.ModelAdmin):
    list_display = ['doctor_link', 'patient_link']
    search_fields = ['doctor__email', 'patient__email']
    list_filter = ['doctor__doctorprofile__specialization']

    def doctor_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.doctor.id])
        return format_html('<a href="{}">{}</a>', url, obj.doctor)
    
    doctor_link.short_description = "Doctor"
    doctor_link.admin_order_field = 'doctor__email'

    def patient_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.patient.id])
        return format_html('<a href="{}">{}</a>', url, obj.patient)
    
    patient_link.short_description = "Patient"
    patient_link.admin_order_field = 'patient__email'

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == 'doctor':
            kwargs['queryset'] = User.objects.filter(doctorprofile__isnull=False)
        elif db_field.name == 'patient':
            kwargs['queryset'] = User.objects.filter(patientprofile__isnull=False)
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

    def save_model(self, request, obj, form, change):
        if obj.doctor == obj.patient:
            raise ValidationError("The doctor and patient cannot be the same user.")
        super().save_model(request, obj, form, change)

class UserAdmin(admin.ModelAdmin):
    list_display = ['email', 'get_account_type', 'is_active']
    search_fields = ['email']
    list_filter = ['is_active']
    inlines = [DoctorPatientRelationInlineAsDoctor, DoctorPatientRelationInlineAsPatient]

    def get_account_type(self, obj):
        if hasattr(obj, 'patientprofile'):
            return 'Patient'
        elif hasattr(obj, 'doctorprofile'):
            return 'Doctor'
        return 'None'

    get_account_type.admin_order_field = 'account_type'
    get_account_type.short_description = 'Account Type'

admin.site.unregister(User)
admin.site.register(User, UserAdmin)
admin.site.register(PatientProfile, PatientProfileAdmin)
admin.site.register(DoctorProfile, DoctorProfileAdmin)
admin.site.register(DoctorPatientRelation, DoctorPatientRelationAdmin)