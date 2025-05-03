# Create a new file in migrations directory, e.g., 0005_chat_access_view.py

from django.db import migrations

class Migration(migrations.Migration):

    dependencies = [
        ('api', '0004_project_users'),  # Make sure this is the latest migration
    ]

    operations = [
        migrations.RunSQL(
            """
            CREATE VIEW chat_access_view AS
            SELECT 
                c.id AS chat_id,
                u.id AS user_id,
                u.username,
                'direct' AS access_type
            FROM api_chat c
            JOIN api_chatuser cu ON c.id = cu.chat_id
            JOIN api_user u ON cu.user_id = u.id
            WHERE cu.view = TRUE
            
            UNION
            
            SELECT 
                c.id AS chat_id,
                u.id AS user_id,
                u.username,
                'project' AS access_type
            FROM api_chat c
            JOIN api_project p ON c.project_id = p.id
            JOIN api_userproject up ON p.id = up.project_id
            JOIN api_user u ON up.user_id = u.id
            WHERE NOT EXISTS (
                SELECT 1 FROM api_chatuser cu 
                WHERE cu.chat_id = c.id AND cu.user_id = u.id AND cu.view = FALSE
            )
            
            UNION
            
            SELECT 
                c.id AS chat_id,
                u.id AS user_id,
                u.username,
                'organization' AS access_type
            FROM api_chat c
            JOIN api_project p ON c.project_id = p.id
            JOIN api_event e ON p.event_id = e.id
            JOIN api_calendar cal ON e.calendar_id = cal.id
            JOIN api_userorganisation uo ON cal.organisation_id = uo.organisation_id
            JOIN api_user u ON uo.user_id = u.id
            WHERE NOT EXISTS (
                SELECT 1 FROM api_chatuser cu 
                WHERE cu.chat_id = c.id AND cu.user_id = u.id AND cu.view = FALSE
            );
            """,
            "DROP VIEW IF EXISTS chat_access_view;"
        )
    ]