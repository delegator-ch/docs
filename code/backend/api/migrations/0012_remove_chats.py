from django.db import migrations

class Migration(migrations.Migration):

    dependencies = [
        ('api', '0011_role_level'),
    ]

    operations = [
        migrations.RunSQL("DELETE FROM api_chat;", reverse_sql=""),
    ]
