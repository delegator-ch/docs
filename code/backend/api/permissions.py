from rest_framework.permissions import BasePermission
from rest_framework.exceptions import PermissionDenied

from .models import Calendar, Event, UserProject
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
    Ensures the user can access (or write to) the calendar in the request.
    """

    def has_permission(self, request, view):
        if view.action in ['create']:
            calendar_id = request.data.get('calendar')
            if not calendar_id:
                raise PermissionDenied("Calendar ID is required.")
            accessible = get_user_accessible_calendars(request.user)
            if not accessible.filter(id=calendar_id).exists():
                raise PermissionDenied("You don't have access to this calendar.")
        return True

    def has_object_permission(self, request, view, obj):
        """
        For updates: check if the event's calendar is accessible.
        If changing calendar, check the new one too.
        """
        accessible = get_user_accessible_calendars(request.user)
        if view.action in ['update', 'partial_update']:
            new_calendar_id = request.data.get('calendar')
            if new_calendar_id and int(new_calendar_id) != obj.calendar_id:
                if not accessible.filter(id=new_calendar_id).exists():
                    raise PermissionDenied("You don't have permission to move the event to this calendar.")
        return obj.calendar in accessible

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

class IsProjectMember(BasePermission):
    """
    Allows access only to users who are members of the project related to the timetable.
    """

    def has_object_permission(self, request, view, obj):
        user = request.user
        if user.is_staff:
            return True

        return UserProject.objects.filter(
            user=user,
            project=obj.event.project
        ).exists()

    def has_permission(self, request, view):
        if request.method != 'POST':
            return True  # Allow read or other actions, restrict in `has_object_permission`

        event_id = request.data.get('event')
        if not event_id:
            return False

        try:
            event = Event.objects.select_related('project').get(id=event_id)
        except Event.DoesNotExist:
            return False

        return UserProject.objects.filter(
            user=request.user,
            project=event.project
        ).exists()

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