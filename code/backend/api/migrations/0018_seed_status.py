from django.db import migrations

def seed_roles(apps, schema_editor):
    Statuses = apps.get_model('api', 'Status')
    Statuses.objects.update_or_create(id=1, defaults={'name': 'Backlog'})
    Statuses.objects.update_or_create(id=2, defaults={'name': 'In-Progress'})
    Statuses.objects.update_or_create(id=3, defaults={'name': 'Done'})

class Migration(migrations.Migration):

    dependencies = [
        ('api', '0017_alter_song_nr'),
    ]

    operations = [
        migrations.RunPython(seed_roles),
    ]
