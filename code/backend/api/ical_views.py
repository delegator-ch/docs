from django.http import HttpResponse
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.urls import reverse
from django.conf import settings

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response  # This was missing

from .models import Calendar, User
from .calendar_token import CalendarSubscription
from .ical_utils import generate_ical_for_calendar, generate_ical_for_user

import logging
logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([AllowAny])
def calendar_ical_feed(request, token):
    """
    Provide an iCalendar feed for a specific calendar.
    
    This endpoint is publicly accessible with a valid token,
    allowing users to subscribe to calendars in their calendar app.
    """
    # Find the subscription token
    subscription = get_object_or_404(CalendarSubscription, token=token, is_active=True)
    
    # Update the last_used timestamp
    subscription.last_used = timezone.now()
    subscription.save()
    
    # Generate the iCalendar data
    ical_data = generate_ical_for_calendar(subscription.calendar, request)
    
    # Return as .ics file
    response = HttpResponse(ical_data, content_type='text/calendar')
    response['Content-Disposition'] = 'attachment; filename="calendar.ics"'
    return response


@api_view(['GET'])
@permission_classes([AllowAny])
def user_ical_feed(request, token):
    """
    Provide an iCalendar feed for all events accessible to a user.
    
    This endpoint is publicly accessible with a valid token,
    allowing users to subscribe to all their events in their calendar app.
    """
    # Find the subscription token
    subscription = get_object_or_404(
        CalendarSubscription, 
        token=token, 
        calendar=None,  # "All calendars" token
        is_active=True
    )
    
    # Update the last_used timestamp
    subscription.last_used = timezone.now()
    subscription.save()
    
    # Generate the iCalendar data
    ical_data = generate_ical_for_user(subscription.user, request)
    
    # Return as .ics file
    response = HttpResponse(ical_data, content_type='text/calendar')
    response['Content-Disposition'] = 'attachment; filename="events.ics"'
    return response


@api_view(['GET'])
def create_calendar_subscription(request, calendar_id):
    """
    Create or refresh a calendar subscription token.
    
    This endpoint requires authentication and returns a URL
    that can be used to subscribe to a calendar.
    """
    calendar = get_object_or_404(Calendar, id=calendar_id)
    
    # Check permissions
    from .utils import get_user_accessible_calendars
    if calendar not in get_user_accessible_calendars(request.user):
        return Response(
            {"detail": "You don't have access to this calendar."},
            status=403
        )
    
    # Create or get a subscription token
    subscription = calendar.get_or_create_subscription(user=request.user)
    
    # Generate the subscription URL
    subscription_url = subscription.get_subscription_url(request)
    
    return Response({
        "subscription_url": subscription_url,
        "token": subscription.token,
        "calendar_id": calendar.id,
        "calendar_name": calendar.organisation.name
    })


@api_view(['GET'])
def create_user_subscription(request):
    """
    Create or refresh a subscription token for all user events.
    
    This endpoint requires authentication and returns a URL
    that can be used to subscribe to all events accessible to the user.
    """
    # Create or get a subscription token
    from .calendar_token import CalendarSubscription
    
    subscription = CalendarSubscription.objects.filter(
        user=request.user,
        calendar=None,
        is_active=True
    ).first()
    
    if not subscription:
        subscription = CalendarSubscription.objects.create(
            user=request.user,
            calendar=None,
            name="All My Events"
        )
    
    # Generate the subscription URL
    subscription_url = subscription.get_subscription_url(request)
    
    return Response({
        "subscription_url": subscription_url,
        "token": subscription.token,
        "name": "All My Events"
    })


@api_view(['GET'])
def list_subscriptions(request):
    """
    List all calendar subscriptions for the current user.
    """
    subscriptions = CalendarSubscription.objects.filter(user=request.user)
    
    data = []
    for sub in subscriptions:
        calendar_name = sub.calendar.organisation.name if sub.calendar else "All My Events"
        data.append({
            "id": sub.id,
            "name": sub.name or calendar_name,
            "subscription_url": sub.get_subscription_url(request),
            "token": sub.token,
            "calendar_id": sub.calendar.id if sub.calendar else None,
            "created": sub.created,
            "last_used": sub.last_used,
            "is_active": sub.is_active
        })
    
    return Response(data)


@api_view(['DELETE'])
def revoke_subscription(request, subscription_id):
    """
    Revoke (deactivate) a calendar subscription.
    """
    subscription = get_object_or_404(
        CalendarSubscription,
        id=subscription_id,
        user=request.user  # Ensure user can only revoke their own subscriptions
    )
    
    subscription.is_active = False
    subscription.save()
    
    return Response({"detail": "Subscription revoked successfully."})