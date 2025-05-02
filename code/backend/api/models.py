# models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

class User(AbstractUser):
    created = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.username


class Organisation(models.Model):
    name = models.CharField(max_length=255)
    since = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        return self.name


class Role(models.Model):
    name = models.CharField(max_length=100)
    
    def __str__(self):
        return self.name


class UserOrganisation(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.CASCADE)
    
    class Meta:
        unique_together = ('user', 'organisation')
    
    def __str__(self):
        return f"{self.user} - {self.organisation} ({self.role})"


class Calendar(models.Model):
    organisation = models.ForeignKey(Organisation, on_delete=models.CASCADE)
    
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
    user = models.ForeignKey(User, on_delete=models.CASCADE)
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
    user = models.ForeignKey(User, on_delete=models.CASCADE)
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


class Contact(models.Model):
    first_name = models.CharField(max_length=255)
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=50, blank=True)
    email = models.EmailField(blank=True)
    bemerkung = models.TextField(blank=True)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    events = models.ManyToManyField(Event, through='ContactEvent')
    
    def __str__(self):
        return f"{self.first_name} {self.name}"


class ContactEvent(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    contact = models.ForeignKey(Contact, on_delete=models.CASCADE)
    
    class Meta:
        unique_together = ('event', 'contact')
    
    def __str__(self):
        return f"{self.contact} - {self.event}"


class Email(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    sender = models.ForeignKey(Contact, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Email from {self.sender} regarding {self.event}"


class History(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    activity = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user} - {self.activity}"


class Status(models.Model):
    name = models.CharField(max_length=100)
    
    def __str__(self):
        return self.name


class Task(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
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
    project = models.ForeignKey(Project, on_delete=models.CASCADE, primary_key=True)
    song = models.ForeignKey(Song, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    
    def __str__(self):
        return self.title


class Moodboard(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Moodboard for {self.project}"


class Mood(models.Model):
    moodboard = models.ForeignKey(Moodboard, on_delete=models.CASCADE)
    image_url = models.URLField()
    vote = models.IntegerField(default=0)
    
    def __str__(self):
        return f"Mood {self.id} in {self.moodboard}"


class Audio(models.Model):
    song = models.ForeignKey(Song, on_delete=models.CASCADE)
    audio_url = models.URLField()
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    description = models.TextField(blank=True)
    
    def __str__(self):
        return f"Audio for {self.song}"


class AudioComment(models.Model):
    audio = models.ForeignKey(Audio, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    timestamp = models.TimeField()  # Position in the audio
    
    def __str__(self):
        return f"Comment by {self.user} on {self.audio}"


class Storyboard(models.Model):
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    image_url = models.URLField()
    order = models.IntegerField(default=0)
    externe = models.IntegerField(default=0)
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Storyboard {self.id} for {self.project}"


class Retro(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    has_been_checked = models.BooleanField(default=False)
    learning = models.TextField(blank=True)
    
    def __str__(self):
        return f"Retro for {self.event}"


class Question(models.Model):
    title = models.CharField(max_length=255)
    name = models.CharField(max_length=255)
    
    def __str__(self):
        return self.title


class Evaluation(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    rating = models.IntegerField()
    comment = models.TextField(blank=True)
    created = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('question', 'user')
    
    def __str__(self):
        return f"{self.user}'s evaluation of {self.question}"


class Vote(models.Model):
    vote = models.BooleanField()
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Vote by {self.user}"


class Account(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    name = models.CharField(max_length=255, default="Main Account")
    
    def __str__(self):
        return f"Account for {self.project}"


class Transaction(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateTimeField(default=timezone.now)
    soll_account = models.ForeignKey(Account, related_name='debits', on_delete=models.CASCADE)
    haben_account = models.ForeignKey(Account, related_name='credits', on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Transaction of {self.amount} on {self.date.strftime('%Y-%m-%d')}"


class Type(models.Model):
    name = models.CharField(max_length=255)
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    
    def __str__(self):
        return self.name


class Piece(models.Model):
    serial = models.CharField(max_length=100, unique=True)
    name = models.CharField(max_length=255)
    image_url = models.URLField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    types = models.ManyToManyField(Type, through='PieceType')
    
    def __str__(self):
        return self.name


class PieceType(models.Model):
    type = models.ForeignKey(Type, on_delete=models.CASCADE)
    piece = models.ForeignKey(Piece, on_delete=models.CASCADE)
    
    class Meta:
        unique_together = ('type', 'piece')
    
    def __str__(self):
        return f"{self.piece} - {self.type}"


class Stack(models.Model):
    piece = models.ForeignKey(Piece, on_delete=models.CASCADE)
    size = models.CharField(max_length=50)
    amount = models.IntegerField(default=0)
    
    def __str__(self):
        return f"{self.piece} - {self.size} ({self.amount})"


class StackMovement(models.Model):
    stack = models.ForeignKey(Stack, on_delete=models.CASCADE)
    amount = models.IntegerField()
    date = models.DateTimeField(default=timezone.now)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Movement of {self.amount} for {self.stack} on {self.date.strftime('%Y-%m-%d')}"


class Vision(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    content = models.TextField()
    priority = models.IntegerField(default=0)
    
    def __str__(self):
        return self.title


class Meeting(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE)
    date = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        return f"Meeting for {self.project} on {self.date.strftime('%Y-%m-%d')}"


class TalkingPoint(models.Model):
    title = models.CharField(max_length=255)
    content = models.TextField(blank=True)
    order = models.IntegerField(default=0)
    meeting = models.ForeignKey(Meeting, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    
    class Meta:
        ordering = ['order']
    
    def __str__(self):
        return self.title


class Decision(models.Model):
    meeting = models.ForeignKey(Meeting, on_delete=models.CASCADE)
    content = models.TextField()
    
    def __str__(self):
        return f"Decision for {self.meeting}"