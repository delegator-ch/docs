# permissions.py
from rest_framework.permissions import BasePermission
from rest_framework.exceptions import PermissionDenied
from .models import Calendar
from .utils import get_user_accessible_calendars  # or wherever you defined it

from rest_framework.permissions import BasePermission
from .utils import user_has_chat_access

from rest_framework.permissions import BasePermission
from rest_framework.exceptions import PermissionDenied
from .utils import get_user_accessible_chats

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