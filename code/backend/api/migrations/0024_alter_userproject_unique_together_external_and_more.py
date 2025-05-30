# Generated by Django 4.2.10 on 2025-05-25 14:54

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0023_remove_chat_project_project_chat'),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name='userproject',
            unique_together=set(),
        ),
        migrations.CreateModel(
            name='External',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created', models.DateTimeField(auto_now_add=True)),
                ('project', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='api.project')),
                ('role', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='api.role')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'unique_together': {('user', 'project')},
            },
        ),
        migrations.RemoveField(
            model_name='userproject',
            name='project',
        ),
        migrations.RemoveField(
            model_name='userproject',
            name='role',
        ),
        migrations.RemoveField(
            model_name='userproject',
            name='user',
        ),
        migrations.AlterField(
            model_name='project',
            name='users',
            field=models.ManyToManyField(related_name='projects', through='api.External', to=settings.AUTH_USER_MODEL),
        ),
    ]
