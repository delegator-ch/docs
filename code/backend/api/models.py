# models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.conf import settings
from django.utils import timezone
from django.urls import reverse

from django.urls import reverse
from django.conf import settings
import logging

from django.utils.crypto import get_random_string
from datetime import timedelta

# So the song nr can be auto generated
from django.db.models.signals import pre_save
from django.dispatch import receiver
from .calendar_token import CalendarSubscription
from django.db.models.signals import post_save

ROLE_LEVEL_CORE_TEAM = 2    # Long-term members
ROLE_LEVEL_TEAM = 3   # Short-term members
ROLE_LEVEL_FAMILY_FRIENDS = 4 # Family and friends
ROLE_LEVEL_FANS = 5       # Fans/general public




# Define User model first, before any other models
class User(AbstractUser):
    created = models.DateTimeField(auto_now_add=True)
    
    # Add related_name arguments to avoid clashes with auth.User
    groups = models.ManyToManyField(
        'auth.Group',
        related_name='api_user_groups',
        blank=True,
        help_text='The groups this user belongs to.',
        verbose_name='groups',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='api_user_permissions',
        blank=True,
        help_text='Specific permissions for this user.',
        verbose_name='user permissions',
    )
    is_premium = models.BooleanField(default=False)
    created = models.DateTimeField(auto_now_add=True)
    invite_code = models.CharField(max_length=8, unique=True, db_index=True)

    def __str__(self):
        return self.username

    def get_ical_url(self, request=None):
        # Get the iCalendar URL for all this user's events
        # Get or create a subscription for all user's calendars
        from .calendar_token import CalendarSubscription
        from django.urls import reverse  # Missing import
        
        subscription = CalendarSubscription.objects.filter(
            user=self, 
            calendar=None,
            is_active=True
        ).first()
        
        if not subscription:
            subscription = CalendarSubscription.objects.create(
                user=self,
                calendar=None,
                name="All My Events"
            )
        
        url = reverse('user-ical', kwargs={'token': subscription.token})
        if request:
            url = request.build_absolute_uri(url)
        elif hasattr(settings, 'SITE_URL'):
            url = f"{settings.SITE_URL}{url}"
        
        return url
    
    def save(self, *args, **kwargs):
        if not self.invite_code:
            self.invite_code = self.generate_unique_invite_code()
        super().save(*args, **kwargs)
    
    @classmethod
    def generate_unique_invite_code(cls):
        """Generate a unique 8-character alphanumeric code"""
        chars = string.ascii_uppercase + string.digits
        while True:
            code = ''.join(random.choices(chars, k=8))
            if not cls.objects.filter(invite_code=code).exists():
                return code
    
    # Add related_name arguments to avoid clashes with auth.User
    groups = models.ManyToManyField(
        'auth.Group',
        related_name='api_user_groups',
        blank=True,
        help_text='The groups this user belongs to.',
        verbose_name='groups',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='api_user_permissions',
        blank=True,
        help_text='Specific permissions for this user.',
        verbose_name='user permissions',
    )
    is_premium = models.BooleanField(default=False)

    def __str__(self):
        return self.username

    def get_ical_url(self, request=None):
        # Get the iCalendar URL for all this user's events
        # Get or create a subscription for all user's calendars
        from .calendar_token import CalendarSubscription
        
        subscription = CalendarSubscription.objects.filter(
            user=self, 
            calendar=None,
            is_active=True
        ).first()
        
        if not subscription:
            subscription = CalendarSubscription.objects.create(
                user=self,
                calendar=None,
                name="All My Events"
            )
        
        url = reverse('user-ical', kwargs={'token': subscription.token})
        if request:
            url = request.build_absolute_uri(url)
        elif hasattr(settings, 'SITE_URL'):
            url = f"{settings.SITE_URL}{url}"
        
        return url

#not for every user
class Organisation(models.Model):
    name = models.CharField(max_length=255)
    since = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        return self.name

#not for every user
class Role(models.Model):
    name = models.CharField(max_length=100)
    level = models.IntegerField(default=ROLE_LEVEL_FANS)  # Default to lowest access
    
    def __str__(self):
        return self.name

#only for admins
class UserOrganisation(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.CASCADE)
    
    class Meta:
        unique_together = ('user', 'organisation')
    
    def __str__(self):
        return f"{self.user} - {self.organisation} ({self.role})"

# Only access (CRUD) on projectes your are added to
# or access (CRUD) on organisation your are added 
# or access via user_id
# In models.py

class Calendar(models.Model):
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True)
    
    # Your existing Calendar model methods...
    
    def __str__(self):
        return f"Calendar for {self.organisation}"
    
    # Add the get_ical_url method here
    def get_ical_url(self, request=None):
        """Get the public iCalendar URL for this calendar"""
        try:
            # Generate a subscription token if none exists
            subscription = self.get_or_create_subscription()
            
            if not subscription:
                # Return an empty string or None if no subscription could be created
                return ""
            
            url = reverse('calendar-ical', kwargs={'token': subscription.token})
            if request:
                url = request.build_absolute_uri(url)
            elif hasattr(settings, 'SITE_URL'):
                url = f"{settings.SITE_URL}{url}"
            
            return url
        except Exception as e:
            # For debugging, log the error
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error generating iCal URL: {str(e)}")
            
            # Return an empty string to avoid breaking the API response
            return ""
    
    # You also need to add the get_or_create_subscription method here
    def get_or_create_subscription(self, user=None):
        """Get or create a subscription token for this calendar"""
        # The implementation of this method goes here
        # This would be the improved version I provided earlier

# Only access (CRUD) on calender you have access to
class Event(models.Model):
    calendar = models.ForeignKey(Calendar, on_delete=models.CASCADE)
    start = models.DateTimeField()
    end = models.DateTimeField()
    is_gig = models.BooleanField(default=False)
    
    def __str__(self):
        return f"Event on {self.start.strftime('%H:%M')} - {self.end.strftime('%H:%M')}"

#Backlog, in-progress
#Not editable by normal users
class Status(models.Model):
    name = models.CharField(max_length=100)
    
    def __str__(self):
        return self.name


 # Chat access via org or project and exlcuded via ChatUser
# Chat are created automaticly on a project or they belong to the org
# Each chat alwazs belongs to a org
class Chat(models.Model):
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    name = models.CharField(max_length=255, default="Chat")
    created = models.DateTimeField(auto_now_add=True)
    min_role_level = models.IntegerField(
        choices=[
            (ROLE_LEVEL_CORE_TEAM, "Core Team Only"),
            (ROLE_LEVEL_TEAM, "Contributors and Above"),
            (ROLE_LEVEL_FAMILY_FRIENDS, "Family, Friends and Above"),
            (ROLE_LEVEL_FANS, "Everyone (including Fans)"),
        ],
        default=ROLE_LEVEL_FANS
    )
    
    def __str__(self):
        if self.project:
            return f"Project Chat: {self.project}"
        elif self.organisation:
            return f"Org Chat: {self.name} ({self.organisation.name})"
        return f"Independent Chat: {self.name}"
    
    def user_has_access(self, user):
        """Check if a user has access based on role level"""
        if user.is_staff:
            return True
            
        # Direct access via ChatUser always takes precedence
        direct_access = self.chatuser_set.filter(user=user)
        if direct_access.exists():
            return direct_access.first().view
            
        # Project-based access
        if self.project and External.objects.filter(user=user, project=self.project).exists():
            return True
            
        # Organisation-based access with role level check
        if self.organisation:
            user_org = UserOrganisation.objects.filter(
                user=user, 
                organisation=self.organisation
            ).first()
            
            if user_org and user_org.role.level <= self.min_role_level:
                return True
                
        return False  

# Only access (CRUD) on projectes your are added to
class Project(models.Model):

    users = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        through='external',
        related_name='projects'
    )    

    status = models.ForeignKey(Status, on_delete=models.CASCADE, blank=True)
    name = models.CharField(max_length=255)
    event = models.ForeignKey(Event, on_delete=models.SET_NULL, null=True, blank=True)
    deadline = models.DateTimeField(null=True, blank=True)
    priority = models.IntegerField(default=0)
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    chat = models.OneToOneField(Chat, on_delete=models.CASCADE, null=True, blank=True)

    def __str__(self):
        return f"Project {self.id}"

@receiver(post_save, sender=Project)
def create_project_chat(sender, instance, created, **kwargs):
    print(f"Signal triggered: created={created}, has_chat={hasattr(instance, 'chat')}")
    if created and not instance.chat:  # Changed this line
        chat = Chat.objects.create(
            organisation=instance.organisation,
            name=f"Project Chat: {instance.name}",
            min_role_level=ROLE_LEVEL_TEAM
        )
        instance.chat = chat
        instance.save()


# Only can see all your chats by user_id or all chats your added to
# Only can add and remove user on chats with speific roles
class ChatUser(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    chat = models.ForeignKey(Chat, on_delete=models.CASCADE)
    view = models.BooleanField(default=True)
    write = models.BooleanField(default=True)
    since = models.DateTimeField(auto_now_add=True)
    include_history = models.BooleanField(default=True)
    muted = models.BooleanField(default=False)  # New field for muting chat notifications
    
    class Meta:
        unique_together = ('user', 'chat')
    
    def __str__(self):
        muted_status = " (muted)" if self.muted else ""
        return f"{self.user} in {self.chat}{muted_status}"

# Only access (CRUD) on projectes your are added to
# or access (CRUD) on organisation your are added to with the roles
class Message(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    chat = models.ForeignKey(Chat, on_delete=models.CASCADE)
    content = models.TextField()
    sent = models.DateTimeField(auto_now_add=True)
    edited = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"Message by {self.user} at {self.sent.strftime('%Y-%m-%d %H:%M')}"

# Only read and write on orginisations your added to
class Song(models.Model):
    nr = models.IntegerField(editable=False)  # Make it non-editable since it's auto-generated
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    
    def __str__(self):
        return self.name

# So we can update song number automatcily
@receiver(pre_save, sender=Song)
def set_song_number(sender, instance, **kwargs):
    # Only set nr if this is a new song (doesn't have an ID yet)
    if not instance.pk:
        # Find the highest nr for songs in this organization
        max_nr = Song.objects.filter(organisation=instance.organisation).aggregate(
            models.Max('nr')
        )['nr__max']
        
        # If no songs exist yet for this org, start at 1, otherwise increment
        instance.nr = 1 if max_nr is None else max_nr + 1

# Only access (CRUD) on projectes your are added to
class Timetable(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    time = models.TimeField()
    name = models.CharField(max_length=255)
    
    def __str__(self):
        return f"{self.name} at {self.time.strftime('%H:%M')}"

# Only access (CRUD) on projectes your are added to
class Setlist(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    time = models.TimeField()
    name = models.CharField(max_length=255)
    song = models.ForeignKey(Song, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"{self.name} - {self.song} at {self.time.strftime('%H:%M')}"

# Only read and write on orginisations your added to
class History(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    activity = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user} - {self.activity}"

# Only access (CRUD) on projectes your are added to
class Task(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    content = models.TextField(blank=True)
    duration = models.IntegerField(default=0)  # in minutes
    status = models.ForeignKey(Status, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    deadline = models.DateTimeField(null=True, blank=True)
    dependent_on_task = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True)
    event = models.ForeignKey(Event, on_delete=models.SET_NULL, null=True, blank=True)
    
    def __str__(self):
        return self.title

# Only access (CRUD) on projectes your are added to
class Recording(models.Model):
    project = models.OneToOneField(Project, on_delete=models.CASCADE, primary_key=True)
    song = models.ForeignKey(Song, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    
    def __str__(self):
        return self.title

# Add this to your models.py file

class External(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'project')
    
    def __str__(self):
        return f"{self.user.username} in {self.project}"

class ChatAccessView(models.Model):
    """
    A database view that shows all users with access to each chat.
    This is a read-only model.
    """
    chat_id = models.IntegerField()
    user_id = models.IntegerField()
    username = models.CharField(max_length=150)
    access_type = models.CharField(max_length=20)
    
    class Meta:
        managed = False
        db_table = 'chat_access_view'

class OrganisationInvitation(models.Model):
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    invited_by = models.ForeignKey(User, on_delete=models.CASCADE)
    invited_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_invitations')
    role = models.ForeignKey(Role, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.CASCADE)
    token = models.CharField(max_length=64, unique=True, db_index=True)
    created = models.DateTimeField(auto_now_add=True)
    expires = models.DateTimeField()
    accepted = models.BooleanField(default=False)
    declined = models.BooleanField(default=False)
    
    class Meta:
        unique_together = ('organisation', 'invited_user')  # Changed from 'email'
    
    def save(self, *args, **kwargs):
        if not self.token:
            self.token = get_random_string(64)
        if not self.expires:
            self.expires = timezone.now() + timedelta(days=7)
        super().save(*args, **kwargs)
    
    def is_expired(self):
        return timezone.now() > self.expires
    
    def can_accept(self):
        return not self.accepted and not self.declined and not self.is_expired()
    
    def __str__(self):
        return f"Invitation to {self.organisation.name} for {self.email}"