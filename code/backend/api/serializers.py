from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Organisation, Role, UserOrganisation, Calendar, Event, Project, Chat,
    ChatUser, Message, Song, Timetable, Setlist, History, Status, Task, Recording, External, ChatAccessView, OrganisationInvitation, BugReport
)

# Add this serializer to your serializers.py file
from .calendar_token import CalendarSubscription

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'password', 'created', 'is_premium']
        read_only_fields = ['created']
        extra_kwargs = {'password': {'write_only': True}}
    
    def create(self, validated_data):
        # Extract the password
        password = validated_data.pop('password')
        
        # Create the user instance
        user = User.objects.create_user(**validated_data)
        
        # Set the password properly (this handles the hashing)
        user.set_password(password)
        user.save()
        
        return user
    
    def update(self, instance, validated_data):
        # Handle password updates separately
        password = validated_data.pop('password', None)
        
        # Update other fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        # If password was provided, update it
        if password:
            instance.set_password(password)
        
        instance.save()
        return instance

class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = '__all__'

class OrganisationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Organisation
        fields = '__all__'

class UserOrganisationSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    organisation_details = OrganisationSerializer(source='organisation', read_only=True)
    role_details = RoleSerializer(source='role', read_only=True)
    
    class Meta:
        model = UserOrganisation
        fields = ['id', 'user', 'organisation', 'role', 'user_details', 'organisation_details', 'role_details']

class CalendarSerializer(serializers.ModelSerializer):
    organisation_details = OrganisationSerializer(source='organisation', read_only=True)
    
    class Meta:
        model = Calendar
        fields = ['id', 'organisation', 'organisation_details']

class EventSerializer(serializers.ModelSerializer):
    calendar_details = CalendarSerializer(source='calendar', read_only=True)
    
    class Meta:
        model = Event
        fields = ['id', 'calendar', 'start', 'end', 'is_gig', 'calendar_details']

class ChatSerializer(serializers.ModelSerializer):
    organisation_details = OrganisationSerializer(source='organisation', read_only=True)
    project_details = serializers.SerializerMethodField()  # Add this
    
    class Meta:
        model = Chat
        fields = ['id', 'organisation', 'name', 'created', 'min_role_level',
                 'organisation_details', 'project_details', 'project']  # Add project_details
    
    def get_project_details(self, obj):
        print(f"Chat ID: {obj.id}")
        print(f"Has project attr: {hasattr(obj, 'project')}")
        print(f"Project value: {getattr(obj, 'project', 'NOT FOUND')}")
        
        try:
            if hasattr(obj, 'project') and obj.project:
                print("Project exists, returning details")
                return {
                    'id': obj.project.id,
                    'name': obj.project.name,
                    'priority': obj.project.priority,
                    'deadline': obj.project.deadline,
                    'organisation': obj.organisation.id,
                    'status': obj.project.status.id if obj.project.status else None
                }
            print("No project or project is None")
            return None
        except Exception as e:
            print(f"Exception: {e}")
            return None
            

class ProjectSerializer(serializers.ModelSerializer):
    event_details = EventSerializer(source='event', read_only=True)
    chat_details = ChatSerializer(source='chat', read_only=True)  # Add chat details
    
    class Meta:
        model = Project
        fields = ['id', 'name', 'event', 'deadline', 'priority', 'event_details', 
                 'organisation', 'status', 'chat', 'chat_details']  # Add chat fields


class ChatUserSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    chat_details = ChatSerializer(source='chat', read_only=True)
    
    class Meta:
        model = ChatUser
        fields = ['id', 'user', 'chat', 'view', 'write', 'since', 'include_history', 'user_details', 'chat_details']

class MessageSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    chat_details = ChatSerializer(source='chat', read_only=True)
    
    class Meta:
        model = Message
        fields = ['id', 'user', 'chat', 'content', 'sent', 'edited', 'user_details', 'chat_details']
        read_only_fields = ['user', 'sent']  # Add user as read-only

class SongSerializer(serializers.ModelSerializer):
    organisation_details = OrganisationSerializer(source='organisation', read_only=True)
    
    class Meta:
        model = Song
        fields = ['id', 'nr', 'name', 'description', 'organisation', 'organisation_details']

class TimetableSerializer(serializers.ModelSerializer):
    event_details = EventSerializer(source='event', read_only=True)
    
    class Meta:
        model = Timetable
        fields = ['id', 'event', 'time', 'name', 'event_details']

class SetlistSerializer(serializers.ModelSerializer):
    event_details = EventSerializer(source='event', read_only=True)
    song_details = SongSerializer(source='song', read_only=True)
    
    class Meta:
        model = Setlist
        fields = ['id', 'event', 'time', 'name', 'song', 'event_details', 'song_details']

class HistorySerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = History
        fields = ['id', 'user', 'activity', 'timestamp', 'user_details']

class StatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = Status
        fields = '__all__'

class TaskSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    project_details = ProjectSerializer(source='project', read_only=True)
    status_details = StatusSerializer(source='status', read_only=True)
    event_details = EventSerializer(source='event', read_only=True)
    dependent_task_details = serializers.SerializerMethodField()
    
    class Meta:
        model = Task
        fields = [
            'id', 'user', 'project', 'title', 'content', 'duration', 'status',
            'created', 'updated', 'deadline', 'dependent_on_task', 'event',
            'user_details', 'project_details', 'status_details', 'event_details',
            'dependent_task_details'
        ]
        read_only_fields = ['created', 'updated']
        extra_kwargs = {
            'user': {'required': False}  # Make user optional in the serializer
        }
        
    def get_dependent_task_details(self, obj):
        if obj.dependent_on_task:
            return {
                'id': obj.dependent_on_task.id,
                'title': obj.dependent_on_task.title
            }
        return None

class RecordingSerializer(serializers.ModelSerializer):
    project_details = ProjectSerializer(source='project', read_only=True)
    song_details = SongSerializer(source='song', read_only=True)
    
    class Meta:
        model = Recording
        fields = ['project', 'song', 'title', 'description', 'project_details', 'song_details']

# Nested serializers for more detailed views
class ProjectDetailSerializer(serializers.ModelSerializer):
    event_details = EventSerializer(source='event', read_only=True)
    tasks = TaskSerializer(source='task_set', many=True, read_only=True)
    
    class Meta:
        model = Project
        fields = ['id', 'name', 'event', 'deadline', 'priority', 'event_details', 'tasks', 'organisation', 'status', 'chat']

class EventDetailSerializer(serializers.ModelSerializer):
    calendar_details = CalendarSerializer(source='calendar', read_only=True)
    timetables = TimetableSerializer(source='timetable_set', many=True, read_only=True)
    setlists = SetlistSerializer(source='setlist_set', many=True, read_only=True)
    projects = ProjectSerializer(source='project_set', many=True, read_only=True)
    
    class Meta:
        model = Event
        fields = ['id', 'calendar', 'start', 'end', 'is_gig', 'calendar_details',
                 'timetables', 'setlists', 'projects']

class UserDetailSerializer(serializers.ModelSerializer):
    organisations = serializers.SerializerMethodField()
    tasks = TaskSerializer(source='task_set', many=True, read_only=True)
    messages = MessageSerializer(source='message_set', many=True, read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'created',
                 'organisations', 'tasks', 'messages']
        read_only_fields = ['created']
    
    def get_organisations(self, obj):
        user_orgs = UserOrganisation.objects.filter(user=obj)
        return UserOrganisationSerializer(user_orgs, many=True).data

class ExternalSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    project_details = ProjectSerializer(source='project', read_only=True)
    role_details = RoleSerializer(source='role', read_only=True)
    
    class Meta:
        model = External
        fields = ['id', 'user', 'project', 'role', 'created', 'user_details', 'project_details', 'role_details']
        read_only_fields = ['created']

class ChatAccessSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatAccessView
        fields = ['chat_id', 'user_id', 'username', 'access_type']

class CalendarSubscriptionSerializer(serializers.ModelSerializer):
    subscription_url = serializers.SerializerMethodField()
    calendar_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CalendarSubscription
        fields = ['id', 'user', 'calendar', 'token', 'name', 'created', 
                 'last_used', 'is_active', 'subscription_url', 'calendar_name']
        read_only_fields = ['token', 'created', 'last_used']
    
    def get_subscription_url(self, obj):
        request = self.context.get('request')
        return obj.get_subscription_url(request)
    
    def get_calendar_name(self, obj):
        if obj.calendar:
            return obj.calendar.organisation.name
        return "All Calendars"


# Also update your CalendarSerializer to include the iCal URL
class CalendarSerializer(serializers.ModelSerializer):
    organisation_details = OrganisationSerializer(source='organisation', read_only=True)
    ical_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Calendar
        fields = ['id', 'organisation', 'organisation_details', 'ical_url']
    
    def get_ical_url(self, obj):
        request = self.context.get('request')
        return obj.get_ical_url(request)


# Update your UserSerializer to include an iCal URL for all events
class UserDetailSerializer(serializers.ModelSerializer):
    organisations = serializers.SerializerMethodField()
    tasks = TaskSerializer(source='task_set', many=True, read_only=True)
    messages = MessageSerializer(source='message_set', many=True, read_only=True)
    ical_url = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'created',
                 'organisations', 'tasks', 'messages', 'ical_url', 'is_premium']
        read_only_fields = ['created', 'is_premium']
    
    def get_organisations(self, obj):
        user_orgs = UserOrganisation.objects.filter(user=obj)
        return UserOrganisationSerializer(user_orgs, many=True).data
        
    def get_ical_url(self, obj):
        request = self.context.get('request')
        return obj.get_ical_url(request)

class OrganisationInvitationSerializer(serializers.ModelSerializer):
    invite_code = serializers.CharField()
    invitation_url = serializers.SerializerMethodField()
    can_accept = serializers.SerializerMethodField()
    is_expired = serializers.SerializerMethodField()

    class Meta:
        model = OrganisationInvitation
        fields = [
            'id', 'organisation', 'invited_by', 'invite_code', 'role',
            'invitation_url', 'can_accept', 'is_expired'
        ]
        read_only_fields = ['invited_by']

    def get_invitation_url(self, obj):
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(f'/invitations/{obj.token}/')
        return f'/invitations/{obj.token}/'
    
    def get_can_accept(self, obj):
        return obj.can_accept()
    
    def get_is_expired(self, obj):
        return obj.is_expired()

class InviteCodeSerializer(serializers.ModelSerializer):    
    class Meta:
        model = User
        fields = ['invite_code', 'is_premium']  # Add this line
        read_only_fields = ['invite_code', 'is_premium']  # Added invite_code to read_only_fiel ds
class BugReportSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = BugReport
        fields = ['id', 'user', 'email', 'title', 'description', 'created', 'user_details']
        read_only_fields = ['user', 'created']
    
    def validate(self, data):
        request = self.context.get('request')
        
        # If user is authenticated, don't require email
        if request and request.user.is_authenticated:
            data.pop('email', None)  # Remove email if provided
        else:
            # For anonymous users, email is required
            if not data.get('email'):
                raise serializers.ValidationError("Email is required for anonymous reports.")
        
        return data