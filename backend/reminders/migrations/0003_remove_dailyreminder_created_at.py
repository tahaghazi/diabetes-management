# Generated by Django 5.1.5 on 2025-04-07 16:22

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('reminders', '0002_dailyreminder_created_at'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='dailyreminder',
            name='created_at',
        ),
    ]
