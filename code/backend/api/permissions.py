from rest_framework.permissions import BasePermission
from rest_framework.exceptions import PermissionDenied
from rest_framework import permissions


from .models import Calendar, Event, UserProject, UserOrganisation, Project
from .utils import (
    get_user_accessible_calendars,
    get_user_accessible_chats,
    user_has_chat_access,
    user_has_project_event_access
)

class CanAccessChat(BasePermission):
    """
    Permission to check if user can access a chat.
    """
    def has_object_permission(self, request, view, obj):
        return user_has_chat_access(request.user, obj)

class CanAccessCalendar(BasePermission):
    """
    Ensures the user can access (read/write) the calendar in the request.
    Checks permissions for all CRUD operations.
    """

    def has_permission(self, request, view):
        # For create operations, check if user has access to the specified calendar
        if view.action == 'create':
            calendar_id = request.data.get('calendar')
            if not calendar_id:
                raise PermissionDenied("Calendar ID is required.")
            
            accessible = get_user_accessible_calendars(request.user)
            if not accessible.filter(id=calendar_id).exists():
                raise PermissionDenied("You don't have access to this calendar.")
        
        # For list/retrieve, the filtering is done in get_queryset
        return True

    def has_object_permission(self, request, view, obj):
        """
        Check permissions for retrieve, update, partial_update, destroy actions.
        For retrieve: Check if user can access this calendar
        For update/delete: Check if user can access both current and new calendar (if changing)
        """
        # Get calendars the user can access
        accessible = get_user_accessible_calendars(request.user)
        
        # For all object operations, check if user has access to the object's calendar
        if obj.calendar not in accessible:
            return False
        
        # For update operations, also check if user has access to the new calendar (if changing)
        if view.action in ['update', 'partial_update']:
            new_calendar_id = request.data.get('calendar')
            if new_calendar_id and int(new_calendar_id) != obj.calendar.id:
                if not accessible.filter(id=new_calendar_id).exists():
                    return False
        
        return True

class HasSongPermission(BasePermission):
    """
    Permission to check if user has the right role in an organization to access songs.
    """
    def has_permission(self, request, view):
        user = request.user
        
        # Staff users have full access
        if user.is_staff:
            return True
        
        # Define which role IDs have permission to manage songs
        # Adjust these IDs based on your actual Role model data
        SONG_MANAGER_ROLE_IDS = [1, 2]  # Example: 1=Admin, 2=Music Director
        
        # Check if user has any of the required roles in any organization
        has_role = UserOrganisation.objects.filter(
            user=user,
            role_id__in=SONG_MANAGER_ROLE_IDS
        ).exists()
        
        # For safe methods like GET, allow access if the user belongs to any organization
        if request.method in permissions.SAFE_METHODS:
            is_in_org = UserOrganisation.objects.filter(user=user).exists()
            return has_role or is_in_org
        
        # For unsafe methods (POST, PUT, DELETE), require specific roles
        return has_role

class IsMessageOwnerOrReadOnly(BasePermission):
    """
    Custom permission to only allow owners of a message to edit or delete it.
    """

    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any authenticated user.
        if request.method in SAFE_METHODS:
            return True

        # Write/delete permissions are only allowed to the message owner.
        return obj.user == request.user

class IsPartOfOrganisation(BasePermission):
    """
    Allows access only to users who are part of at least one organisation.
    """
    def has_permission(self, request, view):
        user = request.user
        return user.is_staff or UserOrganisation.objects.filter(user=user).exists()

class IsPartOfOrganisationAndStaff(BasePermission):
    """
    Allows access only to users who are part of an organisation
    and have a staff-like role (e.g. Admin, Manager).
    """
    STAFF_ROLE_IDS = [1, 2]  # Adjust according to your Role model

    def has_permission(self, request, view):
        user = request.user
        return user.is_staff or UserOrganisation.objects.filter(
            user=user,
            role_id__in=self.STAFF_ROLE_IDS
        ).exists()

    """
    Permission to check if a user can create an organisation.
    """
    def has_permission(self, request, view):
        # Allow all authenticated users to create organizations
        if request.method == 'POST':
            return request.user.is_authenticated
            
        # For other methods, use the default behavior
        return True

class IsProjectMember(BasePermission):
    def has_object_permission(self, request, view, obj):
        user = request.user
        if user.is_staff:
            return True

        # For objects with an event (like Setlist, Timetable)
        if hasattr(obj, 'event'):
            # If event is None, skip this check
            if obj.event:
                # Check direct project access
                related_projects = Project.objects.filter(event=obj.event)
                if UserProject.objects.filter(
                    user=user,
                    project__in=related_projects
                ).exists():
                    return True
                    
                # Check organization access via event's calendar
                if obj.event.calendar and hasattr(obj.event.calendar, 'organisation'):
                    org = obj.event.calendar.organisation
                    return UserOrganisation.objects.filter(
                        user=user,
                        organisation=org
                    ).exists()
        
        # For objects with direct project relationship (like Task)
        if hasattr(obj, 'project'):
            # Check direct project access
            if UserProject.objects.filter(
                user=user,
                project=obj.project
            ).exists():
                return True
                
            # Check organization access via project
            if hasattr(obj.project, 'organisation'):
                return UserOrganisation.objects.filter(
                    user=user,
                    organisation=obj.project.organisation
                ).exists()

        return False
        
    def has_permission(self, request, view):
        if request.method != 'POST':
            return True

        user = request.user

        project_id = request.data.get('project')
        if project_id:
            try:
                if UserProject.objects.filter(user=user, project_id=project_id).exists():
                    return True
                project = Project.objects.get(id=project_id)
                if project.organisation and UserOrganisation.objects.filter(user=user, organisation=project.organisation).exists():
                    return True
            except Project.DoesNotExist:
                pass

        event_id = request.data.get('event')
        if event_id:
            try:
                event = Event.objects.get(id=event_id)
                projects = Project.objects.filter(event=event)
                if UserProject.objects.filter(user=user, project__in=projects).exists():
                    return True
                if event.calendar and hasattr(event.calendar, 'organisation'):
                    return UserOrganisation.objects.filter(user=user, organisation=event.calendar.organisation).exists()
            except Event.DoesNotExist:
                pass

        return False


class HasProjectAccess(BasePermission):
    """
    Permission to check if user has access to a project.
    """
    def has_object_permission(self, request, view, obj):
        user = request.user
        
        # Staff can access all projects
        if user.is_staff:
            return True
        
        # Check if project belongs to user's organization
        if obj.event and obj.event.calendar and obj.event.calendar.organisation:
            organisation = obj.event.calendar.organisation
            if UserOrganisation.objects.filter(user=user, organisation=organisation).exists():
                return True
        
        # If not in the organization, check direct project access
        return UserProject.objects.filter(user=user, project=obj).exists()