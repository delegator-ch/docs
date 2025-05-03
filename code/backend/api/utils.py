
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