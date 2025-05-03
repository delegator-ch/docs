# models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.conf import settings
from django.utils import timezone

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


class Calendar(models.Model):
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True) # not required. If null it a project calender
    
    def __str__(self):
        return f"Calendar for {self.organisation}"

class Event(models.Model):
    calendar = models.ForeignKey(Calendar, on_delete=models.CASCADE)
    start = models.TimeField()
    end = models.TimeField()
    is_gig = models.BooleanField(default=False)
    
    def __str__(self):
        return f"Event on {self.start.strftime('%H:%M')} - {self.end.strftime('%H:%M')}"


class Project(models.Model):

    users = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        through='UserProject',
        related_name='projects'
    )    

    event = models.ForeignKey(Event, on_delete=models.SET_NULL, null=True, blank=True)
    deadline = models.DateTimeField(null=True, blank=True)
    priority = models.IntegerField(default=0)

    
    def __str__(self):
        return f"Project {self.id}"


class Chat(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Chat for {self.project}"


class ChatUser(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    chat = models.ForeignKey(Chat, on_delete=models.CASCADE)
    view = models.BooleanField(default=True)
    write = models.BooleanField(default=True)
    since = models.DateTimeField(auto_now_add=True)
    include_history = models.BooleanField(default=True)
    
    class Meta:
        unique_together = ('user', 'chat')
    
    def __str__(self):
        return f"{self.user} in {self.chat}"


class Message(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    chat = models.ForeignKey(Chat, on_delete=models.CASCADE)
    content = models.TextField()
    sent = models.DateTimeField(auto_now_add=True)
    edited = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"Message by {self.user} at {self.sent.strftime('%Y-%m-%d %H:%M')}"


class Song(models.Model):
    nr = models.IntegerField(default=0)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    
    def __str__(self):
        return self.name


class Timetable(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    time = models.TimeField()
    name = models.CharField(max_length=255)
    
    def __str__(self):
        return f"{self.name} at {self.time.strftime('%H:%M')}"


class Setlist(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    time = models.TimeField()
    name = models.CharField(max_length=255)
    song = models.ForeignKey(Song, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"{self.name} - {self.song} at {self.time.strftime('%H:%M')}"


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
