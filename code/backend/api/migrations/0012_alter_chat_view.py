# Create a new migration file
from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):

    dependencies = [
        ('api', '0009_project_organisation'),  # Update to your latest migration
    ]

    operations = [
        # Add level field to Role model
        migrations.AddField(
            model_name='role',
            name='level',
            field=models.IntegerField(default=40),  # ROLE_LEVEL_FANS
        ),
        
        # Create OrganisationChat model
        migrations.CreateModel(
            name='OrganisationChat',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255)),
                ('created', models.DateTimeField(auto_now_add=True)),
                ('min_role_level', models.IntegerField(choices=[(10, 'Core Team Only'), (20, 'Contributors and Above'), (30, 'Family, Friends and Above'), (40, 'Everyone (including Fans)')], default=40)),
                ('organisation', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='api.organisation')),
            ],
        ),
        
        # Add organisation_chat field to Chat model
        migrations.AddField(
            model_name='chat',
            name='organisation_chat',
            field=models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='api.organisationchat'),
        ),
        
        # Make project field optional
        migrations.AlterField(
            model_name='chat',
            name='project',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='api.project'),
        ),
    ]