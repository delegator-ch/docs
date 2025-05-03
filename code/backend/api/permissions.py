# permissions.py
from rest_framework.permissions import BasePermission
from rest_framework.exceptions import PermissionDenied
from .models import Calendar
from .utils import get_user_accessible_calendars  # or wherever you defined it

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
