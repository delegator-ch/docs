

from .models import UserOrganisation, Project, Chat, External, Calendar, Event
from rest_framework.exceptions import PermissionDenied
from django.db.models import Q

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

def get_user_accessible_chats(user):
    if user.is_staff:
        return Chat.objects.all()
    return Chat.objects.filter(
        Q(chatuser__user=user, chatuser__view=True) |
        Q(project__userproject__user=user) |
        Q(organisation__userorganisation__user=user)
    ).distinct()


def get_user_project_events(user):
    """
    Get all events from projects the user is a member of.
    """
    # Get projects the user is a member of
    user_projects = Project.objects.filter(userproject__user=user)
    
    # Get events from those projects
    return Event.objects.filter(project__in=user_projects)

def user_has_project_event_access(user, event):
    """
    Check if a user has access to an event through project membership.
    """
    # Check if the user is a member of any project associated with this event
    return UserProject.objects.filter(
        user=user,
        project__event=event
    ).exists()


def get_user_project_queryset(user, base_queryset, project_field='project'):
    """
    Return a filtered queryset for a user based on project membership.
    """
    if user.is_staff:
        return base_queryset

    return base_queryset.filter(
        **{f'{project_field}__userproject__user': user}
    ).distinct()

def check_project_access(user, project):
    if user.is_staff:
        return
    
    # Check direct project access
    if UserProject.objects.filter(user=user, project=project).exists():
        return
    
    # Also check organization access
    if hasattr(project, 'organisation') and project.organisation:
        if UserOrganisation.objects.filter(
            user=user, 
            organisation=project.organisation
        ).exists():
            return
    
    raise PermissionDenied("You don't have access to this project.")

def get_user_accessible_calendars(user):
    """
    Get all calendars a user has access to through:
    1. Organization membership
    2. User's own calendars (where user is directly assigned)
    3. Project membership (via External)
    
    Returns a QuerySet of Calendar objects.
    """
    # Staff can access all calendars
    if user.is_staff:
        return Calendar.objects.all()
    
    # Get user's organizations
    user_orgs = UserOrganisation.objects.filter(user=user).values_list('organisation_id', flat=True)
    
    # Get calendars from user's organizations
    org_calendars = Calendar.objects.filter(organisation_id__in=user_orgs)
    
    # Get user's directly assigned calendars
    direct_calendars = Calendar.objects.filter(user=user)
    
    # Get calendars from projects where user is a member (via External)
    project_calendars = Calendar.objects.filter(
        event__project__external__user=user
    )
    
    # Combine the queries and apply distinct to remove duplicates
    return (org_calendars | direct_calendars | project_calendars).distinct()