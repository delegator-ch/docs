from icalendar import Calendar as ICalendar, Event as ICalEvent
from datetime import datetime, date
import uuid
import pytz
from django.conf import settings
from django.urls import reverse

from .models import Calendar, Event, Task

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
    cal.add('x-wr-timezone', 'UTC')
    
    # Get all events for this calendar
    events = Event.objects.filter(calendar=calendar)
    
    # Add events to calendar
    for event in events:
        ical_event = create_event_entry(event, request)
        cal.add_component(ical_event)
    
    # Add task deadlines to calendar
    # Get tasks related to events in this calendar
    tasks_with_deadlines = Task.objects.filter(
        event__calendar=calendar,
        deadline__isnull=False
    )
    
    for task in tasks_with_deadlines:
        ical_task = create_task_deadline_entry(task, request)
        cal.add_component(ical_task)
    
    return cal.to_ical()


def generate_ical_for_user(user, request=None):
    """
    Generate a personal iCalendar feed for a user's tasks and assigned events.
    
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
    cal.add('x-wr-calname', f"{user.username}'s Personal Tasks & Events")
    cal.add('x-wr-timezone', 'UTC')
    
    # Get events from projects the user is assigned to
    from .models import Project, UserProject
    user_projects = Project.objects.filter(userproject__user=user)
    events = Event.objects.filter(project__in=user_projects)
    
    # Add events to calendar
    for event in events:
        ical_event = create_event_entry(event, request)
        cal.add_component(ical_event)
    
    # Add task deadlines to calendar
    # Get only user's own tasks with deadlines
    tasks_with_deadlines = Task.objects.filter(
        user=user,
        deadline__isnull=False
    )
    
    for task in tasks_with_deadlines:
        ical_task = create_task_deadline_entry(task, request)
        cal.add_component(ical_task)
    
    return cal.to_ical()


def create_event_entry(event, request=None):
    """Create an iCal event entry for an Event model"""
    ical_event = ICalEvent()
    
    # Generate a UID for this event
    uid = f"event-{event.id}@{settings.SITE_DOMAIN}" if hasattr(settings, 'SITE_DOMAIN') else f"event-{event.id}@bandmanager.app"
    ical_event.add('uid', uid)
    
    # Event name/summary
    summary = f"Gig: {event.calendar.organisation.name}" if event.is_gig else f"Event: {event.calendar.organisation.name}"
    ical_event.add('summary', summary)
    
    # Handle the event start and end times
    if isinstance(event.start, datetime):
        start_datetime = event.start
        end_datetime = event.end
    else:
        if hasattr(event, 'date'):
            event_date = event.date
        else:
            event_date = event.start.date()
            
        start_datetime = datetime.combine(event_date, event.start)
        end_datetime = datetime.combine(event_date, event.end)
    
    # Add the proper start and end times
    ical_event.add('dtstart', start_datetime)
    ical_event.add('dtend', end_datetime)
    
    # Handle timezone
    timezone = pytz.timezone('UTC')
    if start_datetime.tzinfo is None:
        start_datetime = timezone.localize(start_datetime)
    if end_datetime.tzinfo is None:
        end_datetime = timezone.localize(end_datetime)
    
    # Add creation timestamp
    now = datetime.now(timezone)
    ical_event.add('dtstamp', now)
    
    # Add URL to view the event
    if request and hasattr(settings, 'FRONTEND_URL'):
        event_url = f"{settings.FRONTEND_URL}/events/{event.id}"
        ical_event.add('url', event_url)
    
    # Add description
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
    
    return ical_event


def create_task_deadline_entry(task, request=None):
    """Create an iCal event entry for a Task deadline"""
    ical_event = ICalEvent()
    
    # Generate a UID for this task deadline
    uid = f"task-deadline-{task.id}@{settings.SITE_DOMAIN}" if hasattr(settings, 'SITE_DOMAIN') else f"task-deadline-{task.id}@bandmanager.app"
    ical_event.add('uid', uid)
    
    # Task summary
    summary = f"DEADLINE: {task.title}"
    ical_event.add('summary', summary)
    
    # Use deadline as the event time (make it a short event)
    if isinstance(task.deadline, datetime):
        start_time = task.deadline
        end_time = task.deadline
    else:
        # If deadline is date only, set time to end of day
        start_time = datetime.combine(task.deadline, datetime.min.time().replace(hour=23, minute=59))
        end_time = start_time
    
    # Handle timezone
    timezone = pytz.timezone('UTC')
    if start_time.tzinfo is None:
        start_time = timezone.localize(start_time)
    if end_time.tzinfo is None:
        end_time = timezone.localize(end_time)
    
    ical_event.add('dtstart', start_time)
    ical_event.add('dtend', end_time)
    
    # Add creation timestamp
    now = datetime.now(timezone)
    ical_event.add('dtstamp', now)
    
    # Add URL to view the task
    if request and hasattr(settings, 'FRONTEND_URL'):
        task_url = f"{settings.FRONTEND_URL}/tasks/{task.id}"
        ical_event.add('url', task_url)
    
    # Add description
    description = f"Task Deadline\n"
    description += f"Project: {task.project.name}\n" if task.project else ""
    description += f"Status: {task.status.name}\n" if task.status else ""
    if task.content:
        description += f"Description: {task.content}\n"
    if task.duration:
        description += f"Estimated Duration: {task.duration} minutes\n"
    
    ical_event.add('description', description)
    
    # Mark as deadline/reminder
    ical_event.add('categories', 'DEADLINE')
    
    return ical_event