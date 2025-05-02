from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Organisation, Role, UserOrganisation, Calendar, Event, Project, Chat,
    ChatUser, Message, Song, Timetable, Setlist, Contact, ContactEvent,
    Email, History, Status, Task, Recording, Moodboard, Mood, Audio,
    AudioComment, Storyboard, Retro, Question, Evaluation, Vote, Account,
    Transaction, Type, Piece, PieceType, Stack, StackMovement, Vision,
    Meeting, TalkingPoint, Decision
)

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'created']
        read_only_fields = ['created']


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


class ProjectSerializer(serializers.ModelSerializer):
    event_details = EventSerializer(source='event', read_only=True)
    
    class Meta:
        model = Project
        fields = ['id', 'event', 'deadline', 'priority', 'event_details']


class ChatSerializer(serializers.ModelSerializer):
    project_details = ProjectSerializer(source='project', read_only=True)
    
    class Meta:
        model = Chat
        fields = ['id', 'project', 'project_details']


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


class SongSerializer(serializers.ModelSerializer):
    class Meta:
        model = Song
        fields = '__all__'


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


class ContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = Contact
        fields = ['id', 'first_name', 'name', 'phone', 'email', 'bemerkung', 'created', 'updated']
        read_only_fields = ['created', 'updated']


class ContactEventSerializer(serializers.ModelSerializer):
    event_details = EventSerializer(source='event', read_only=True)
    contact_details = ContactSerializer(source='contact', read_only=True)
    
    class Meta:
        model = ContactEvent
        fields = ['id', 'event', 'contact', 'event_details', 'contact_details']


class EmailSerializer(serializers.ModelSerializer):
    event_details = EventSerializer(source='event', read_only=True)
    sender_details = ContactSerializer(source='sender', read_only=True)
    
    class Meta:
        model = Email
        fields = ['id', 'event', 'sender', 'event_details', 'sender_details']


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


class MoodboardSerializer(serializers.ModelSerializer):
    project_details = ProjectSerializer(source='project', read_only=True)
    
    class Meta:
        model = Moodboard
        fields = ['id', 'project', 'project_details']


class MoodSerializer(serializers.ModelSerializer):
    moodboard_details = MoodboardSerializer(source='moodboard', read_only=True)
    
    class Meta:
        model = Mood
        fields = ['id', 'moodboard', 'image_url', 'vote', 'moodboard_details']


class AudioSerializer(serializers.ModelSerializer):
    song_details = SongSerializer(source='song', read_only=True)
    user_details = UserSerializer(source='user', read_only=True)
    project_details = ProjectSerializer(source='project', read_only=True)
    
    class Meta:
        model = Audio
        fields = ['id', 'song', 'audio_url', 'user', 'project', 'created', 'description',
                 'song_details', 'user_details', 'project_details']
        read_only_fields = ['created']


class AudioCommentSerializer(serializers.ModelSerializer):
    audio_details = AudioSerializer(source='audio', read_only=True)
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = AudioComment
        fields = ['id', 'audio', 'user', 'content', 'created', 'updated', 'timestamp',
                 'audio_details', 'user_details']
        read_only_fields = ['created', 'updated']


class StoryboardSerializer(serializers.ModelSerializer):
    project_details = ProjectSerializer(source='project', read_only=True)
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = Storyboard
        fields = ['id', 'created', 'updated', 'image_url', 'order', 'externe',
                 'project', 'user', 'project_details', 'user_details']
        read_only_fields = ['created', 'updated']


class RetroSerializer(serializers.ModelSerializer):
    event_details = EventSerializer(source='event', read_only=True)
    
    class Meta:
        model = Retro
        fields = ['id', 'event', 'has_been_checked', 'learning', 'event_details']


class QuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Question
        fields = '__all__'


class EvaluationSerializer(serializers.ModelSerializer):
    question_details = QuestionSerializer(source='question', read_only=True)
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = Evaluation
        fields = ['id', 'question', 'user', 'rating', 'comment', 'created',
                 'question_details', 'user_details']
        read_only_fields = ['created']


class VoteSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = Vote
        fields = ['id', 'vote', 'user', 'created', 'user_details']
        read_only_fields = ['created']


class AccountSerializer(serializers.ModelSerializer):
    project_details = ProjectSerializer(source='project', read_only=True)
    
    class Meta:
        model = Account
        fields = ['id', 'project', 'name', 'project_details']


class TransactionSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    soll_account_details = AccountSerializer(source='soll_account', read_only=True)
    haben_account_details = AccountSerializer(source='haben_account', read_only=True)
    
    class Meta:
        model = Transaction
        fields = ['id', 'user', 'amount', 'date', 'soll_account', 'haben_account',
                 'user_details', 'soll_account_details', 'haben_account_details']


class TypeSerializer(serializers.ModelSerializer):
    project_details = ProjectSerializer(source='project', read_only=True)
    
    class Meta:
        model = Type
        fields = ['id', 'name', 'project', 'project_details']


class PieceSerializer(serializers.ModelSerializer):
    types = TypeSerializer(many=True, read_only=True)
    
    class Meta:
        model = Piece
        fields = ['id', 'serial', 'name', 'image_url', 'price', 'types']


class PieceTypeSerializer(serializers.ModelSerializer):
    type_details = TypeSerializer(source='type', read_only=True)
    piece_details = PieceSerializer(source='piece', read_only=True)
    
    class Meta:
        model = PieceType
        fields = ['id', 'type', 'piece', 'type_details', 'piece_details']


class StackSerializer(serializers.ModelSerializer):
    piece_details = PieceSerializer(source='piece', read_only=True)
    
    class Meta:
        model = Stack
        fields = ['id', 'piece', 'size', 'amount', 'piece_details']


class StackMovementSerializer(serializers.ModelSerializer):
    stack_details = StackSerializer(source='stack', read_only=True)
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = StackMovement
        fields = ['id', 'stack', 'amount', 'date', 'user', 'stack_details', 'user_details']


class VisionSerializer(serializers.ModelSerializer):
    project_details = ProjectSerializer(source='project', read_only=True)
    
    class Meta:
        model = Vision
        fields = ['id', 'project', 'title', 'content', 'priority', 'project_details']


class MeetingSerializer(serializers.ModelSerializer):
    project_details = ProjectSerializer(source='project', read_only=True)
    
    class Meta:
        model = Meeting
        fields = ['id', 'project', 'date', 'project_details']
        read_only_fields = ['date']


class TalkingPointSerializer(serializers.ModelSerializer):
    meeting_details = MeetingSerializer(source='meeting', read_only=True)
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = TalkingPoint
        fields = ['id', 'title', 'content', 'order', 'meeting', 'user',
                 'meeting_details', 'user_details']


class DecisionSerializer(serializers.ModelSerializer):
    meeting_details = MeetingSerializer(source='meeting', read_only=True)
    
    class Meta:
        model = Decision
        fields = ['id', 'meeting', 'content', 'meeting_details']


# Nested serializers for more detailed views

class ProjectDetailSerializer(serializers.ModelSerializer):
    event_details = EventSerializer(source='event', read_only=True)
    tasks = TaskSerializer(source='task_set', many=True, read_only=True)
    visions = VisionSerializer(source='vision_set', many=True, read_only=True)
    meetings = MeetingSerializer(source='meeting_set', many=True, read_only=True)
    accounts = AccountSerializer(source='account_set', many=True, read_only=True)
    
    class Meta:
        model = Project
        fields = ['id', 'event', 'deadline', 'priority', 'event_details',
                 'tasks', 'visions', 'meetings', 'accounts']


class EventDetailSerializer(serializers.ModelSerializer):
    calendar_details = CalendarSerializer(source='calendar', read_only=True)
    timetables = TimetableSerializer(source='timetable_set', many=True, read_only=True)
    setlists = SetlistSerializer(source='setlist_set', many=True, read_only=True)
    contacts = ContactSerializer(many=True, read_only=True)
    projects = ProjectSerializer(source='project_set', many=True, read_only=True)
    retros = RetroSerializer(source='retro_set', many=True, read_only=True)
    
    class Meta:
        model = Event
        fields = ['id', 'calendar', 'start', 'end', 'is_gig', 'calendar_details',
                 'timetables', 'setlists', 'contacts', 'projects', 'retros']


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


class MeetingDetailSerializer(serializers.ModelSerializer):
    project_details = ProjectSerializer(source='project', read_only=True)
    talking_points = TalkingPointSerializer(source='talkingpoint_set', many=True, read_only=True)
    decisions = DecisionSerializer(source='decision_set', many=True, read_only=True)
    
    class Meta:
        model = Meeting
        fields = ['id', 'project', 'date', 'project_details', 'talking_points', 'decisions']