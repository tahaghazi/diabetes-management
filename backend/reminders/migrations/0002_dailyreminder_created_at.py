# Generated by Django 5.1.5 on 2025-04-07 16:16

import datetime
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('reminders', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='dailyreminder',
            name='created_at',
            field=models.DateTimeField(auto_now_add=True, default=datetime.datetime(2025, 4, 7, 0, 0)),
            preserve_default=False,
        ),
    ]
