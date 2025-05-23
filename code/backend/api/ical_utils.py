from icalendar import Calendar as ICalendar, Event as ICalEvent
from datetime import datetime, date
import uuid
import pytz
from django.conf import settings
from django.urls import reverse

from .models import Calendar, Event

def generate_ical_for_calendar(calendar, request=None, user=None):
    """
    Generate an iCalendar feed for a given calendar.
    
    Args:
        calendar: The Calendar model instance
        request: Optional HTTP request for building absolute URIs
        user: Optional user to filter events by permission
    
    Returns:
        A string containing the iCalendar data
    """
    cal = ICalendar()
    # Set some standard iCalendar properties
    cal.add('prodid', f'-//Band Manager//{settings.SITE_NAME}//EN')
    cal.add('version', '2.0')
    cal.add('calscale', 'GREGORIAN')
    cal.add('method', 'PUBLISH')
    cal.add('x-wr-calname', f"{calendar.organisation.name} Calendar")
    cal.add('x-wr-timezone', 'UTC')  # Default to UTC, can be customized
    
    # Get all events for this calendar
    # Filter by user permissions if needed
    events = Event.objects.filter(calendar=calendar)
    
    # If user is provided, ensure they have access to these events
    # This would need your custom permission logic
    
    for event in events:
        ical_event = ICalEvent()
        
        # Generate a UID for this event (important for updates)
        uid = f"event-{event.id}@{settings.SITE_DOMAIN}" if hasattr(settings, 'SITE_DOMAIN') else f"event-{event.id}@bandmanager.app"
        ical_event.add('uid', uid)
        
        # Event name/summary
        # You might want to customize this based on your event model
        summary = f"Gig: {event.calendar.organisation.name}" if event.is_gig else f"Event: {event.calendar.organisation.name}"
        ical_event.add('summary', summary)
        
        # FIXED: Properly handle the event start and end times
        # Ensure we're using the event date, not today's date
        if isinstance(event.start, datetime):
            start_datetime = event.start
            end_datetime = event.end
        else:
            # Get the event date from the event model
            # This assumes your Event model has a date field or we can extract date from start
            # If event.start is a time and event has a date field:
            if hasattr(event, 'date'):
                event_date = event.date
            else:
                # If no explicit date field, extract date portion from start datetime
                # This assumes event.start has a date component we can use
                event_date = event.start.date()
                
            # Combine the event date with the time
            start_datetime = datetime.combine(event_date, event.start)
            end_datetime = datetime.combine(event_date, event.end)
        
        # Add the proper start and end times
        ical_event.add('dtstart', start_datetime)
        ical_event.add('dtend', end_datetime)
        
        # Only add timezone if the datetime is naive (doesn't have tzinfo)
        timezone = pytz.timezone('UTC')
        if start_datetime.tzinfo is None:
            start_datetime = timezone.localize(start_datetime)
        if end_datetime.tzinfo is None:
            end_datetime = timezone.localize(end_datetime)
        
        # Add creation timestamp
        now = datetime.now(timezone)
        ical_event.add('dtstamp', now)
        
        # Add URL to view the event in your app (if request is provided)
        if request and hasattr(settings, 'FRONTEND_URL'):
            event_url = f"{settings.FRONTEND_URL}/events/{event.id}"
            ical_event.add('url', event_url)
        
        # Add description
        # Include any relevant event details
        description = f"Organization: {event.calendar.organisation.name}\n"
        if event.is_gig:
            description += "Type: Gig\n"
        
        # Add related setlist if any
        setlist_items = event.setlist_set.all().order_by('time')
        if setlist_items.exists():
            description += "\nSetlist:\n"
            for item in setlist_items:
                description += f"- {item.time.strftime('%H:%M')} {item.name}: {item.song.name}\n"
        
        # Add related timetable if any
        timetable_items = event.timetable_set.all().order_by('time')
        if timetable_items.exists():
            description += "\nTimetable:\n"
            for item in timetable_items:
                description += f"- {item.time.strftime('%H:%M')} {item.name}\n"
        
        ical_event.add('description', description)
        
        # Add to calendar
        cal.add_component(ical_event)
    
    return cal.to_ical()


def generate_ical_for_user(user, request=None):
    """
    Generate an iCalendar feed for all events accessible to a user.
    
    Args:
        user: The User model instance
        request: Optional HTTP request for building absolute URIs
    
    Returns:
        A string containing the iCalendar data
    """
    cal = ICalendar()
    # Set some standard iCalendar properties
    cal.add('prodid', f'-//Band Manager//{settings.SITE_NAME}//EN')
    cal.add('version', '2.0')
    cal.add('calscale', 'GREGORIAN')
    cal.add('method', 'PUBLISH')
    cal.add('x-wr-calname', f"{user.username}'s Events")
    cal.add('x-wr-timezone', 'UTC')  # Default to UTC, can be customized
    
    # Get all events the user has access to
    # This leverages your existing permission system
    from .utils import get_user_accessible_calendars
    calendars = get_user_accessible_calendars(user)
    events = Event.objects.filter(calendar__in=calendars)
    
    for event in events:
        ical_event = ICalEvent()
        
        # Generate a UID for this event
        uid = f"event-{event.id}@{settings.SITE_DOMAIN}" if hasattr(settings, 'SITE_DOMAIN') else f"event-{event.id}@bandmanager.app"
        ical_event.add('uid', uid)
        
        # Event name/summary
        summary = f"Gig: {event.calendar.organisation.name}" if event.is_gig else f"Event: {event.calendar.organisation.name}"
        ical_event.add('summary', summary)
        
        # FIXED: Properly handle the event start and end times
        # Ensure we're using the event date, not today's date
        if isinstance(event.start, datetime):
            start_datetime = event.start
            end_datetime = event.end
        else:
            # Get the event date from the event model
            # This assumes your Event model has a date field or we can extract date from start
            # If event.start is a time and event has a date field:
            if hasattr(event, 'date'):
                event_date = event.date
            else:
                # If no explicit date field, extract date portion from start datetime
                # This assumes event.start has a date component we can use
                event_date = event.start.date()
                
            # Combine the event date with the time
            start_datetime = datetime.combine(event_date, event.start)
            end_datetime = datetime.combine(event_date, event.end)
        
        # Add the proper start and end times
        ical_event.add('dtstart', start_datetime)
        ical_event.add('dtend', end_datetime)
        
        # Only add timezone if the datetime is naive (doesn't have tzinfo)
        timezone = pytz.timezone('UTC')
        if start_datetime.tzinfo is None:
            start_datetime = timezone.localize(start_datetime)
        if end_datetime.tzinfo is None:
            end_datetime = timezone.localize(end_datetime)
        
        # Add creation timestamp
        now = datetime.now(timezone)
        ical_event.add('dtstamp', now)
        
        # Add URL to view the event in your app
        if request and hasattr(settings, 'FRONTEND_URL'):
            event_url = f"{settings.FRONTEND_URL}/events/{event.id}"
            ical_event.add('url', event_url)
        
        # Add description with relevant event details
        description = f"Organization: {event.calendar.organisation.name}\n"
        if event.is_gig:
            description += "Type: Gig\n"
        
        # Add related data if needed
        # This can be customized based on your requirements
        
        ical_event.add('description', description)
        
        # Add to calendar
        cal.add_component(ical_event)
    
    return cal.to_ical()