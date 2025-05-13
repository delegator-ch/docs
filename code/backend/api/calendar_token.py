from django.db import models
from django.utils.crypto import get_random_string
from django.urls import reverse
from django.conf import settings
# In your calendar_token.py file (or whichever file contains this model)

class CalendarSubscription(models.Model):
    """
    Model to store calendar subscription tokens.
    This allows secure access to calendar feeds without requiring login.
    """
    user = models.ForeignKey('User', on_delete=models.CASCADE, related_name='calendar_subscriptions')
    calendar = models.ForeignKey('Calendar', on_delete=models.CASCADE, 
                               null=True, blank=True, 
                               related_name='subscription_tokens')
    # If calendar is None, this is a token for all user's calendars
    
    token = models.CharField(max_length=64, unique=True, db_index=True)
    name = models.CharField(max_length=255, blank=True)
    created = models.DateTimeField(auto_now_add=True)
    last_used = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    
    def save(self, *args, **kwargs):
        # Generate a token if one doesn't exist
        if not self.token:
            self.token = get_random_string(64)
        super().save(*args, **kwargs)
    
    def __str__(self):
        calendar_name = self.calendar.organisation.name if self.calendar else "All Calendars"
        return f"{self.user.username} - {calendar_name} ({self.token[:8]}...)"
    
    # Add the get_subscription_url method here
    def get_subscription_url(self, request=None):
        """
        Generate the subscription URL for this token.
        
        Args:
            request: The HTTP request object (for building absolute URLs)
            
        Returns:
            A string containing the subscription URL
        """
        from django.urls import reverse
        
        if self.calendar:
            # URL for a specific calendar
            path = reverse('calendar-ical', kwargs={'token': self.token})
        else:
            # URL for all user's calendars
            path = reverse('user-ical', kwargs={'token': self.token})
        
        if request:
            return request.build_absolute_uri(path)
        
        # If no request is available, try to build a URL from settings
        from django.conf import settings
        if hasattr(settings, 'SITE_URL'):
            return f"{settings.SITE_URL}{path}"
        
        return path  # Return relative path as fallback