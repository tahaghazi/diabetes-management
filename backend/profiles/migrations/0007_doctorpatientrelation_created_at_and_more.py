# Generated by Django 5.1.5 on 2025-05-20 01:47

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('profiles', '0006_alter_doctorpatientrelation_unique_together_and_more'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='doctorpatientrelation',
            name='created_at',
            field=models.DateTimeField(auto_now=True),
        ),
        migrations.AddField(
            model_name='doctorpatientrelation',
            name='status',
            field=models.CharField(choices=[('pending', 'Pending'), ('accepted', 'Accepted'), ('declined', 'Declined')], default='pending', max_length=10),
        ),
        migrations.AlterField(
            model_name='doctorpatientrelation',
            name='doctor',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='doctor_relations', to=settings.AUTH_USER_MODEL),
        ),
        migrations.AlterField(
            model_name='doctorpatientrelation',
            name='patient',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='patient_relations', to=settings.AUTH_USER_MODEL),
        ),
        migrations.AddConstraint(
            model_name='doctorpatientrelation',
            constraint=models.UniqueConstraint(fields=('doctor', 'patient'), name='unique_doctor_patient'),
        ),
    ]
