from rest_framework.permissions import BasePermission, SAFE_METHODS
from rest_framework.exceptions import PermissionDenied
from rest_framework import permissions

from .models import Calendar, Event, External, UserOrganisation, Project
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
    def has_permission(self, request, view):
        """Check permission for create operations (POST)"""
        # Allow GET requests to pass through to has_object_permission
        if request.method in SAFE_METHODS:
            return True
            
        # For POST/create operations, check project access
        if request.method == 'POST':
            user = request.user
            project_id = request.data.get('project')
            
            if not project_id:
                return False  # Project is required
                
            try:
                project = Project.objects.get(id=project_id)
                
                # Check if user is external member of the project
                if External.objects.filter(user=user, project=project).exists():
                    return True
                
                # Check if user has organization access
                if hasattr(project, 'organisation') and project.organisation:
                    if UserOrganisation.objects.filter(
                        user=user, 
                        organisation=project.organisation
                    ).exists():
                        return True
                        
            except Project.DoesNotExist:
                return False
        
        # For other unsafe methods, allow through to object-level permission
        return True

    def has_object_permission(self, request, view, obj):
        """Check permission for object-level operations (GET, PUT, DELETE)"""
        user = request.user
        if user.is_staff:
            return True

        # Check if this is the user's own task
        if hasattr(obj, 'user') and obj.user == user:
            return True

        # Check event-based access
        if hasattr(obj, 'event') and obj.event:
            # Get projects related to this event
            related_projects = Project.objects.filter(event=obj.event)
            if External.objects.filter(
                user=user,
                project__in=related_projects
            ).exists():
                return True
                
            # Check organization access via event calendar
            if obj.event.calendar and hasattr(obj.event.calendar, 'organisation'):
                org = obj.event.calendar.organisation
                if UserOrganisation.objects.filter(
                    user=user,
                    organisation=org
                ).exists():
                    return True
        
        # Check project-based access
        if hasattr(obj, 'project') and obj.project:
            # Check if user is external member of the project
            if External.objects.filter(
                user=user,
                project=obj.project
            ).exists():
                return True
                
            # Check organization access
            if hasattr(obj.project, 'organisation') and obj.project.organisation:
                if UserOrganisation.objects.filter(
                    user=user,
                    organisation=obj.project.organisation
                ).exists():
                    return True

        return False

class HasProjectAccess(BasePermission):
    def has_object_permission(self, request, view, obj):
        user = request.user
        
        if user.is_staff:
            return True
        
        if obj.event and obj.event.calendar and obj.event.calendar.organisation:
            organisation = obj.event.calendar.organisation
            if UserOrganisation.objects.filter(user=user, organisation=organisation).exists():
                return True
        
        return External.objects.filter(user=user, project=obj).exists()