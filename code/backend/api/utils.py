

from .models import UserOrganisation, Project, Chat, UserProject

def user_has_chat_access(user, chat):
    """
    Determine if a user has access to a chat based on:
    1. Organization membership
    2. Project membership
    """
    # Direct access via ChatUser
    if chat.chatuser_set.filter(user=user, view=True).exists():
        return True
    
    # Access via Project membership
    if UserProject.objects.filter(user=user, project=chat.project).exists():
        return True
    
    # Access via Organization (if the project is part of an organization)
    # This assumes you have a way to link projects to organizations
    project_orgs = get_project_organizations(chat.project)
    if UserOrganisation.objects.filter(user=user, organisation__in=project_orgs).exists():
        return True
    
    return False

def get_project_organizations(project):
    """
    Get organizations related to a project.
    You may need to adjust this based on your data model.
    """
    # This is a placeholder - we need to determine how projects and orgs are related
    # If projects have events that have calendars that belong to organizations:
    if project.event and project.event.calendar:
        return [project.event.calendar.organisation]
    
    return []
    
def get_user_accessible_calendars(user):
    """
    Utility function to get all calendars a user has access to.
    """
    # Get organizations the user belongs to with specific roles
    specific_roles = [1, 2, 3]  # IDs of roles that should grant calendar access
    user_orgs = UserOrganisation.objects.filter(
        user=user, 
        role_id__in=specific_roles
    ).values_list('organisation_id', flat=True)
    
    # Get calendars from those organizations
    org_calendars = Calendar.objects.filter(organisation_id__in=user_orgs)
    
    # Get projects the user is part of (via tasks)
    user_projects = Project.objects.filter(task__user=user).distinct()
    
    # Get events from those projects
    project_events = Event.objects.filter(project__in=user_projects)
    
    # Get calendars from those events
    project_calendar_ids = project_events.values_list('calendar_id', flat=True).distinct()
    project_calendars = Calendar.objects.filter(id__in=project_calendar_ids)
    
    # Combine accessible calendars
    return (org_calendars | project_calendars).distinct()