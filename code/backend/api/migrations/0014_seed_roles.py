from django.db import migrations

def seed_roles(apps, schema_editor):
    Role = apps.get_model('api', 'Role')
    Role.objects.update_or_create(id=1, defaults={'name': 'Admin', 'level': 1})
    Role.objects.update_or_create(id=2, defaults={'name': 'Core Team', 'level': 2})
    Role.objects.update_or_create(id=3, defaults={'name': 'Team', 'level': 3})
    Role.objects.update_or_create(id=4, defaults={'name': 'Family & Friends', 'level': 4})
    Role.objects.update_or_create(id=5, defaults={'name': 'Fans', 'level': 5})

class Migration(migrations.Migration):

    dependencies = [
        ('api', '0013_remove_chat_organisation'),  # replace with actual
    ]

    operations = [
        migrations.RunPython(seed_roles),
    ]
