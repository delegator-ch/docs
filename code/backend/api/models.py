# models.py
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class Message(models.Model):
    """Simple chat message model"""
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='messages')
    content = models.TextField()
    timestamp = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        return f"{self.sender.username}: {self.content[:30]}"
    
    class Meta:
        ordering = ['timestamp']