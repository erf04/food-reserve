# Generated by Django 4.2.5 on 2024-07-23 00:51

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0005_user_working_shift_alter_meal_drinks'),
    ]

    operations = [
        migrations.RenameField(
            model_name='supervisorrecord',
            old_name='supervisor',
            new_name='shift_manager',
        ),
    ]
