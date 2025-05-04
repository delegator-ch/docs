# models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.conf import settings
from django.utils import timezone

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
    def __str__(self):
        return self.username

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
class Calendar(models.Model):
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True) # not required. If null it a project calender
    
    def __str__(self):
        return f"Calendar for {self.organisation}"

# Only access (CRUD) on calender you have access to
class Event(models.Model):
    calendar = models.ForeignKey(Calendar, on_delete=models.CASCADE)
    start = models.TimeField()
    end = models.TimeField()
    is_gig = models.BooleanField(default=False)
    
    def __str__(self):
        return f"Event on {self.start.strftime('%H:%M')} - {self.end.strftime('%H:%M')}"

# Only access (CRUD) on projectes your are added to
class Project(models.Model):

    users = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        through='UserProject',
        related_name='projects'
    )    

    event = models.ForeignKey(Event, on_delete=models.SET_NULL, null=True, blank=True)
    deadline = models.DateTimeField(null=True, blank=True)
    priority = models.IntegerField(default=0)
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)

    def __str__(self):
        return f"Project {self.id}"


class OrganisationChat(models.Model):
    """Chat specific to an organization with role-based access"""
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    created = models.DateTimeField(auto_now_add=True)
    # Minimum role level required to access this chat
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
        return f"{self.name} ({self.organisation.name})"
    
    def user_has_access(self, user):
        """Check if a user has access to this chat based on their role"""
        if user.is_staff:
            return True
            
        # Get the user's role in this organization
        user_org = UserOrganisation.objects.filter(
            user=user, 
            organisation=self.organisation
        ).first()
        
        if not user_org:
            return False
            
        # Check if the user's role level is sufficient
        return user_org.role.level <= self.min_role_level

# Chat access via org or project and exlcuded via ChatUser
# Chat are created automaticly on a project or they belong to the org
# Each chat alwazs belongs to a org
class Chat(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, null=True, blank=True)
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
        if self.project and UserProject.objects.filter(user=user, project=self.project).exists():
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
    nr = models.IntegerField(default=0)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE, null=True, blank=True)
    
    def __str__(self):
        return self.name

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

#Backlog, in-progress
#Not editable by normal users
class Status(models.Model):
    name = models.CharField(max_length=100)
    
    def __str__(self):
        return self.name

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

class UserProject(models.Model):
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
